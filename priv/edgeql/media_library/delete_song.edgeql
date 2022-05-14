# edgedb = :query!

with params := <json>$params
delete Song
filter .id = <uuid>params["id"]
