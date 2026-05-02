# ABOUTME: Reads action JSON from stdin and executes db_write.sh or sqlite3 commands
# ABOUTME: Reads AGENT_NAME, DB_PATH, PROJECT_ROOT from environment

require 'json'

data       = JSON.parse($stdin.read)
db_write   = File.join(ENV.fetch('PROJECT_ROOT'), 'scripts', 'db_write.sh')
agent_name = ENV.fetch('AGENT_NAME')
db_path    = ENV.fetch('DB_PATH')
env        = ENV.to_h.merge('DB_PATH' => db_path)

def sql_escape(value)
  value.to_s.gsub("'", "''")
end

data['actions'].each do |a|
  begin
    case a['type']
    when 'set_role'
      role = sql_escape(a['role'])
      system('sqlite3', db_path,
             "UPDATE agents SET role='#{role}' WHERE name='#{agent_name}';")
    when 'post_message'
      system(env, db_write, 'post_message', agent_name,
             (a['recipient'] || 'ALL').to_s, a['content'].to_s)
    when 'create_proposal'
      system(env, db_write, 'create_proposal', agent_name,
             a['title'].to_s, a['content'].to_s)
    when 'vote'
      system(env, db_write, 'vote', agent_name,
             a['proposal_id'].to_s, (a['vote'] || 'APPROVE').to_s,
             a['comment'].to_s)
    when 'review_artifact'
      system(env, db_write, 'review_artifact', agent_name,
             a['filename'].to_s, (a['vote'] || 'APPROVE').to_s,
             a['comment'].to_s)
    when 'write_artifact'
      filename = File.basename(a['filename'].to_s)
      path = File.join(ENV.fetch('PROJECT_ROOT'), filename)
      File.write(path, a['content'].to_s)
      filename_sql = sql_escape(filename)
      system('sqlite3', db_path,
             "DELETE FROM artifact_reviews WHERE filename='#{filename_sql}';
              INSERT INTO mission_state
                (id, status, artifact_filename, artifact_written_at, completed_at, updated_at)
              VALUES
                (1, 'review', '#{filename_sql}', CURRENT_TIMESTAMP, NULL, CURRENT_TIMESTAMP)
              ON CONFLICT(id) DO UPDATE SET
                status='review',
                artifact_filename=excluded.artifact_filename,
                artifact_written_at=CURRENT_TIMESTAMP,
                completed_at=NULL,
                updated_at=CURRENT_TIMESTAMP;")
    end
  rescue => e
    $stderr.puts "Action error (#{a['type']}): #{e}"
  end
end
