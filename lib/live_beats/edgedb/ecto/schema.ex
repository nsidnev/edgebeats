defmodule LiveBeats.EdgeDB.Ecto.Schema do
  defmacro __using__(_opts \\ []) do
    quote do
      def from_edgedb(nil) do
        nil
      end

      def from_edgedb(data) do
        __MODULE__
        |> struct()
        |> edgedb_changeset(data)
        |> Ecto.Changeset.apply_changes()
      end

      def edgedb_changeset(schema, data) do
        embeds = __MODULE__.__schema__(:embeds)
        fields = __MODULE__.__schema__(:fields)
        virtual_fields = __MODULE__.__schema__(:virtual_fields)
        fields = (fields ++ virtual_fields) -- embeds
        changeset = Ecto.Changeset.cast(schema, data, fields)

        Enum.reduce(embeds, changeset, fn embeded_field, changeset ->
          embeded_module = __MODULE__.__schema__(:embed, embeded_field).related

          Ecto.Changeset.cast_embed(changeset, embeded_field,
            with: &embeded_module.edgedb_changeset/2
          )
        end)
      end
    end
  end
end
