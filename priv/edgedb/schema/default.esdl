module default {
  # cast insensitive string
  scalar type cistr extending str;

  type User {
    property name -> str;
    required property username -> str;
    required property email -> cistr;

    required property role -> str {
      default := "subscriber";
    }

    property profile_tagline -> str;

    property avatar_url -> str;
    property external_homepage_url -> str;

    property confirmed_at -> cal::local_datetime;

    required property inserted_at -> cal::local_datetime {
      default := cal::to_local_datetime(datetime_current(), 'UTC');
    }

    required property updated_at -> cal::local_datetime {
      default := cal::to_local_datetime(datetime_current(), 'UTC');
    }

    property songs_count := count(.<user[is Song]);

    link active_profile_user -> User {
      on target delete allow;
    }

    index on (.email);
    index on (.username);
  }

  type Identity {
    required property provider -> str;
    required property provider_token -> str;
    required property provider_login -> str;
    required property provider_email -> str;
    required property provider_id -> str;

    required property provider_meta -> json {
      default := <json>"{}";
    }

    required property inserted_at -> cal::local_datetime {
      default := cal::to_local_datetime(datetime_current(), 'UTC');
    }

    required property updated_at -> cal::local_datetime {
      default := cal::to_local_datetime(datetime_current(), 'UTC');
    }

    required link user -> User {
      on target delete delete source;
    }

    index on (.provider);
    constraint exclusive on ((.user, .provider));
  }

  type Genre {
    required property title -> str {
      constraint exclusive;
    }

    required property slug -> str {
      constraint exclusive;
    }
  }

  scalar type SongStatus extending enum<Stopped, Playing, Paused>;
  scalar type inet extending bytes;

  type Song {
    required property title -> str;
    property attribution -> str;
    property album_artist -> str;
    required property artist -> str;

    required property duration -> int64 {
      default := 0;
    }

    required property position -> int64 {
      default := 0;
    }

    required property status -> SongStatus {
      default := SongStatus.Stopped;
    }

    required property mp3_url -> str;
    required property mp3_filename -> str;
    required property mp3_filepath -> str;

    required property mp3_filesize -> int64 {
      default := 0;
    }

    property server_ip -> inet;

    property played_at -> datetime;
    property paused_at -> datetime;
    property date_recorded -> cal::local_datetime;
    property date_released -> cal::local_datetime;

    required property inserted_at -> cal::local_datetime {
      default := cal::to_local_datetime(datetime_current(), 'UTC');
    }

    required property updated_at -> cal::local_datetime {
      default := cal::to_local_datetime(datetime_current(), 'UTC');
    }

    link user -> User {
      on target delete allow;
    }

    link genre -> Genre {
      on target delete allow;
    }

    index on (.status);
    constraint exclusive on ((.user, .title, .artist));
  }

  function to_status(status: str) -> optional SongStatus
    using (
      with status := str_title(status)
      select <SongStatus>status if status in {"Stopped", "Playing", "Paused"} else <SongStatus>{}
    )
}
