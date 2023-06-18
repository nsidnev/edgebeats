with
    current_song := <Song><uuid>$song_id,
    old_position := current_song.position,
    songs_count := global current_user.songs_count,
    new_position := <int32>$new_position if <int32>$new_position < songs_count else songs_count - 1,
    decreased_positions := (
        update Song
        filter .id != current_song.id and .position > old_position and .position <= new_position
        set {
            position := .position - 1
        }
    ),
    increased_positions := (
        update Song
        filter .id != current_song.id and .position < old_position and .position >= new_position
        set {
            position := .position + 1
        }
    ),
    updated_song := (
        update current_song
        set {
            position := new_position
        }
    )
select new_position
