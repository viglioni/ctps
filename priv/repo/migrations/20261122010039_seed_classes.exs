defmodule Ctps.Repo.Migrations.SeedClasses do
  use Ecto.Migration

  @classes [
    # {name,       hd, main_attrs,     op,   saves,          skills, gold}
    {"Bárbaro",    12, ["for"],        "and", ["for", "con"], 2,       75},
    {"Bardo",       8, ["cha"],        "and", ["dex", "cha"], 3,       90},
    {"Bruxo",       8, ["cha"],        "and", ["wis", "cha"], 2,      100},
    {"Clérigo",     8, ["wis"],        "and", ["wis", "cha"], 2,      110},
    {"Druida",      8, ["wis"],        "and", ["int", "wis"], 2,       50},
    {"Feiticeiro",  6, ["cha"],        "and", ["con", "cha"], 2,       50},
    {"Guardião",   10, ["dex", "wis"], "and", ["for", "dex"], 3,      150},
    {"Guerreiro",  10, ["for", "dex"], "or",  ["for", "con"], 2,      155},
    {"Ladino",      8, ["dex"],        "and", ["dex", "int"], 4,      100},
    {"Mago",        6, ["int"],        "and", ["int", "wis"], 2,       55},
    {"Monge",       8, ["dex", "wis"], "and", ["for", "dex"], 2,       50},
    {"Paladino",   10, ["for", "cha"], "and", ["wis", "cha"], 2,      150}
  ]

  def up do
    values =
      @classes
      |> Enum.map(fn {name, hd, main, op, saves, skills, gold} ->
        "('#{name}', #{hd}, #{array_lit(main)}, '#{op}', #{array_lit(saves)}, #{skills}, #{gold}, now(), now())"
      end)
      |> Enum.join(",\n  ")

    execute """
    INSERT INTO ctps.classes
      (name, hit_die, main_attrs, main_attrs_bin_op, saving_throw, skill_number, init_gold_option, inserted_at, updated_at)
    VALUES
      #{values}
    """
  end

  def down do
    names = @classes |> Enum.map(fn {n, _, _, _, _, _, _} -> "'#{n}'" end) |> Enum.join(",")
    execute "DELETE FROM ctps.classes WHERE name IN (#{names})"
  end

  defp array_lit(list) do
    inner = list |> Enum.map(&"'#{&1}'") |> Enum.join(",")
    "ARRAY[#{inner}]::text[]"
  end
end
