# LiveBeats with EdgeDB

Play music together with Phoenix LiveView!

Visit [edgebeats.fly.dev](https://edgebeats.fly.dev) to try it out, or run locally:

  * Create a [Github OAuth app](https://docs.github.com/en/developers/apps/building-oauth-apps/creating-an-oauth-app) from [this page](https://github.com/settings/applications/new)
    - Set the app homepage to `http://localhost:4000` and `Authorization callback URL` to `http://localhost:4000/oauth/callbacks/github`
    - After completing the form, click "Generate a new client secret" to obtain your API secret
  * Export your GitHub Client ID and secret:

        export LIVE_BEATS_GITHUB_CLIENT_ID="..."
        export LIVE_BEATS_GITHUB_CLIENT_SECRET="..."

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `edgedb project init`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Changes compared to the original LiveBeats implementation

The main change is replacing PostgreSQL with EdgeDB. What does this mean?
  1. Ecto is preserved, although changes have been made to get rid of the use of `Ecto.Repo` and `Ecto.Query`, since the EdgeDB driver has no adapter for Ecto. At least for now ;)
  2. `Postgrex` has been replaced by `EdgeDB` (wow, thanks, cap). Although `Postgrex` itself was retained as an application dependency in order to implement the support of `EctoNetwork.INET` through `Postgrex.INET`.
  3. Most of the other usual Ecto stuff (`Ecto.Schema`, `Ecto.Changeset`) is mostly as it is, but some changes have been made to be able to run this application without an adapter.
  4. Queries are written using pure EdgeQL instead of Ecto DSL for Elixir and stored in `priv/edgedb/edgeql/<domain>/<query_name>.edgeql` files.
  5. There is no longer `LiveBeats.ReplicaRepo`. It was removed to simplify refactoring, although it can be restored later.
  6. The database schema has been migrated to EdgeQL SDL using a lot of useful EdgeDB features. This includes database migrations, which are now managed through EdgeDB CLI instead of Ecto.
  7. To support encoding/decoding of `EctoNetwork.INET` values, custom codec was implemented for EdgeDB client.

Note:
Although the tests pass, no additional tests were added, and the original cases did not cover the entire project. In addition, the EdgeDB driver itself is quite young and has not been tested in real applications.
ecause of all this, various bugs can (and probably do) exist in the application. If you face them, open the issue in the repository or, if you like, create a PR with a fix. Any type of contribution is welcome!

## Learn more

  * Original LiveBeats repository: https://github.com/fly-apps/live_beats
