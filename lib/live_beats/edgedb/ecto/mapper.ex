defmodule LiveBeats.EdgeDB.Ecto.Mapper do
  defmacro __using__(_opts \\ []) do
    caller_mod = __CALLER__.module

    quote location: :keep do
      alias LiveBeats.EdgeDB.Ecto.Convertable

      def from_edgedb({:ok, result}) do
        {:ok, from_edgedb(result)}
      end

      def from_edgedb({:error, _reason} = error) do
        error
      end

      def from_edgedb(result) do
        Convertable.convert(struct(__MODULE__), result)
      end

      defimpl Convertable, for: __MODULE__ do
        def convert(_schema, nil) do
          nil
        end

        def convert(schema, %EdgeDB.Set{} = set) do
          Enum.map(set, fn item ->
            convert(schema, item)
          end)
        end

        def convert(schema, %EdgeDB.Object{} = object) do
          properties = unquote(caller_mod).__schema__(:fields)
          links = unquote(caller_mod).__schema__(:associations)

          associations =
            Enum.reduce(links, %{}, fn link_name, associations ->
              link = object[link_name]
              association = unquote(caller_mod).__schema__(:association, link_name)

              converted = Convertable.convert(struct(association.related), link)

              case converted do
                nil ->
                  associations

                [] ->
                  associations

                converted ->
                  Map.put(associations, link_name, converted)
              end
            end)

          changeset = Ecto.Changeset.change(schema)

          properties
          |> Enum.reduce(changeset, fn property_name, changeset ->
            property = object[property_name]
            type = unquote(caller_mod).__schema__(:type, property_name)
            converted = Convertable.convert(type, property)

            Ecto.Changeset.put_change(
              changeset,
              property_name,
              converted
            )
          end)
          |> then(fn changeset ->
            Enum.reduce(associations, changeset, fn {link_name, associations}, changeset ->
              Ecto.Changeset.put_assoc(changeset, link_name, associations)
            end)
          end)
          |> Ecto.Changeset.apply_changes()
        end
      end
    end
  end
end
