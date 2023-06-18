with
    song_to_delete := (select <Song><uuid>$song_id),
    updated_positions := (
        update Song
        filter .position > song_to_delete.position
        set {
            position := .position - 1
        }
    )
delete song_to_delete
