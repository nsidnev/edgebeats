# edgedb = :query_required_single!

select count(Song filter .user.id = <uuid>$user_id)
