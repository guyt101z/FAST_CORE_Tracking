module SuspectEvent
  unloadable
  SUSPECT_BATCH_LIMIT = 100
  SUSPECT_TOTAL = 2500
  
  def identify_suspect_events(log = nil)
    candidates = connection.select_rows "SELECT device_id, max(id), count(id) FROM #{table_name} WHERE suspect IS NULL OR duration IS NULL GROUP BY device_id"
    log_info(log,"#{self}: #{candidates.length} possible suspects")
    for row_results in candidates
      device_id,last_event_id,event_count = row_results
      if event_count.to_i > SUSPECT_TOTAL
        log_info(log,"#{self}: #{event_count} total events -- immediately suspect")
        connection.execute "update #{table_name} set suspect = 1 where suspect is null and device_id = #{device_id} and id <= #{last_event_id}"
      else
        true while identify_unterminated_events(device_id,last_event_id,log)
        true while identify_overlapping_events(device_id,last_event_id,log)
        true while identify_overlapped_events(device_id,last_event_id,log)
        connection.execute "update #{table_name} set suspect = 0 where suspect is null and device_id = #{device_id} and id <= #{last_event_id}"
      end
    end
  end
  
private
  def identify_overlapping_events(device_id,last_event_id,log)
      process_suspects("overlapping events for #{device_id}",log,find_by_sql("select a.* from #{table_name} a,#{table_name} b where
        a.device_id = #{device_id} and a.id <= #{last_event_id} and a.suspect is null and
        a.duration > 1 and a.device_id = b.device_id and a.id != b.id and
        b.duration is null and
        b.created_at between a.created_at and adddate(a.created_at,interval (a.duration - 1) minute)
        group by a.id
        limit #{SUSPECT_BATCH_LIMIT}"))
  end
  
  def identify_overlapped_events(device_id,last_event_id,log)
      process_suspects("overlapped events for #{device_id}",log,find_by_sql("select a.* from #{table_name} a,#{table_name} b where
        a.device_id = #{device_id} and a.id <= #{last_event_id} and a.suspect is null and
        a.duration > 1 and a.device_id = b.device_id and a.id != b.id and
        b.duration is not null and adddate(b.created_at,interval b.duration minute) between a.created_at and adddate(a.created_at,interval (a.duration - 1) minute)
        group by a.id
        limit #{SUSPECT_BATCH_LIMIT}"))
  end
  
  def identify_unterminated_events(device_id,last_event_id,log)
      process_suspects("unterminated events for #{device_id}",log,find_by_sql("select a.* from #{table_name} a,#{table_name} b where
        a.device_id = #{device_id} and a.id <= #{last_event_id} and (a.suspect is null or a.suspect = 0) and
        a.duration is null and a.device_id = b.device_id and a.id < b.id
        group by a.id
        limit #{SUSPECT_BATCH_LIMIT}"))
  end
  
  def process_suspects(label,log,events)
    return false unless events.any?
    log_info(log,"#{self}: #{events.length} #{label}" )
    events.each do
        |event|
        event.update_attributes!(:suspect => true)
    end
    return events.length >= SUSPECT_BATCH_LIMIT
  end
  
  def log_info(log,info)
    log ? log.info(info) : puts(info)
  end
end
