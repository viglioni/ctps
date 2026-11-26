defmodule Ctps.Repo.Migrations.SeedBackgrounds do
  use Ecto.Migration

  @feats ~w(
    alert crafter healer lucky magic-initiate-cleric magic-initiate-druid
    magic-initiate-wizard musician savage-attacker skilled tavern-brawler tough
  )

  @backgrounds [
    # {slug, title, a1, a2, a3, gold, feat, description}
    {"acolyte", "Acólito", "int", "wis", "cha", 50, "magic-initiate-cleric",
     "Você se dedicou ao serviço em um templo, localizado em uma aldeia ou em um bosque sagrado, onde realizava ritos em homenagem a um deus ou panteão. Sob a orientação de um sacerdote, você estudou religião e, graças à sua devoção, aprendeu a canalizar um pouco do poder divino para o seu local de culto e para as pessoas que ali oravam."},
    {"wayfarer", "Andarilho", "dex", "wis", "cha", 50, "lucky",
     "Você cresceu nas ruas cercado por rejeitados igualmente malfadados, alguns deles amigos e outros rivais. Você dormia onde podia e fazia bicos por comida. Às vezes, quando a fome se tornava insuportável, você recorria ao furto. Ainda assim, você nunca perdeu seu orgulho e nunca abandonou a esperança. O destino ainda não terminou com você."},
    {"artisan", "Artesão", "for", "dex", "int", 50, "crafter",
     "Você começou a limpar o chão e esfregar balcões na oficina de um artesão por alguns trocados por dia assim que ficou forte o suficiente para carregar um balde. Ao se tornar aprendiz, aprendeu a fabricar artesanatos básicos e a lidar com clientes exigentes, desenvolvendo também um olhar aguçado para detalhes."},
    {"entertainer", "Artista", "for", "dex", "cha", 50, "musician",
     "Você passou a juventude em feiras e festivais itinerantes, fazendo bicos para músicos e acrobatas em troca de aulas. Aprendeu a andar na corda bamba, tocar alaúde de um jeito distinto e recitar poesia com dicção impecável. Até hoje, prospera com aplausos e anseia pelo palco."},
    {"charlatan", "Charlatão", "dex", "con", "cha", 50, "skilled",
     "Assim que você atingiu a idade para pedir uma cerveja, escolheu seu banquinho favorito em cada taverna a quinze quilômetros de onde nasceu. Ao percorrer o circuito de bares e botequins, aprendeu a lidar com os infelizes em busca de mentiras reconfortantes — talvez uma poção falsa ou registros de ancestralidade forjados."},
    {"criminal", "Criminoso", "dex", "con", "int", 50, "alert",
     "Você sobrevivia em becos escuros, furtando pessoas ou assaltando lojas. Talvez fizesse parte de uma pequena gangue de criminosos que se protegiam mutuamente, ou fosse um lobo solitário, enfrentando a guilda dos ladrões locais e os criminosos mais temíveis."},
    {"hermit", "Eremita", "con", "wis", "cha", 50, "healer",
     "Você passou seus primeiros anos isolado em uma cabana ou mosteiro localizado bem além dos arredores do povoado mais próximo. Naqueles dias, seus únicos companheiros eram as criaturas da floresta e aqueles que ocasionalmente faziam uma visita para trazer suprimentos e notícias do mundo externo. A solidão permitia que você passasse muitas horas ponderando os mistérios da criação."},
    {"scribe", "Escriba", "dex", "int", "wis", 50, "skilled",
     "Você passou anos de formação em um scriptorium, um mosteiro dedicado à preservação do conhecimento ou uma agência governamental, onde aprendeu a escrever com uma mão firme e produzir textos finamente escritos. Talvez você tenha escrito documentos governamentais ou copiado tomos de literatura. Você pode ter alguma habilidade como escritor de poesia, narrativa ou pesquisa acadêmica. Acima de tudo, você tem uma atenção cuidadosa aos detalhes, o que lhe ajuda a evitar a introdução de erros aos documentos que você copia e cria."},
    {"farmer", "Fazendeiro", "for", "con", "wis", 50, "tough",
     "Você cresceu perto da terra. Os anos cuidando de animais e cultivando a terra o recompensaram com paciência e boa saúde. Você tem um grande apreço pela generosidade da natureza, juntamente com um respeito saudável pela ira dela."},
    {"guard", "Guarda", "for", "int", "wis", 50, "alert",
     "Seus pés doem quando você se lembra das incontáveis horas que passou em seu posto na torre. Você foi treinado para manter um olho atento para o que ocorria do lado fora da muralha, observando saqueadores vasculhando a floresta próxima, e seu outro olho voltado para dentro da muralha, procurando por assaltantes e encrenqueiros."},
    {"guide", "Guia", "dex", "con", "wis", 50, "magic-initiate-druid",
     "Você cresceu ao ar livre, longe de terras povoadas. Sua casa ficava em qualquer lugar que você escolhesse para estender seu saco de dormir. Há maravilhas na natureza — monstros estranhos, florestas e riachos intocados, ruínas imensas de grandes salões outrora pisados por gigantes — e você aprendeu a se defender enquanto as explorava. De tempos em tempos, você guiava sacerdotes da natureza amigáveis que o instruíam nos fundamentos de canalizar a magia da natureza."},
    {"sailor", "Marinheiro", "for", "dex", "wis", 50, "tavern-brawler",
     "Você viveu como um marinheiro, com o vento nas costas e os conveses balançando sob seus pés. Você já se sentou em bancos de bar em mais portos de escala do que consegue se lembrar, enfrentou grandes tempestades e trocou histórias com pessoas que vivem sob as ondas."},
    {"merchant", "Mercador", "con", "int", "cha", 50, "lucky",
     "Você foi aprendiz de um comerciante, mestre de caravanas ou lojista, aprendendo os fundamentos do comércio. Com ele, viajou bastante e ganhou a vida comprando e vendendo as matérias-primas que os artesãos precisam para praticar seu ofício, ou trabalhos acabados de tais artesãos. Você pode ter transportado mercadorias de um lugar para outro (por navio, carroça ou caravana) ou comprado de comerciantes viajantes e vendido em sua própria loja."},
    {"noble", "Nobre", "for", "int", "cha", 50, "skilled",
     "Você foi criado em um castelo, cercado por riqueza, poder e privilégio. Sua família de aristocratas menores garantiu que você recebesse uma educação de primeira categoria, com conteúdos que você apreciava e outros dos quais se ressentia. Seu tempo no castelo, especialmente as muitas horas que passou observando sua família na corte, também lhe ensinou muito sobre liderança."},
    {"sage", "Sábio", "con", "int", "wis", 50, "magic-initiate-wizard",
     "Você passou seus anos de formação viajando entre mansões e mosteiros, realizando vários bicos e serviços em troca de acesso às bibliotecas desses locais. Suas noites se resumiram a estudar livros e pergaminhos, aprendendo a sabedoria do multiverso — até mesmo os rudimentos da magia — e, agora, sua mente anseia por mais."},
    {"soldier", "Soldado", "for", "dex", "con", 50, "savage-attacker",
     "Você começou a treinar para a guerra assim que atingiu a idade adulta e tem poucas lembranças preciosas da vida antes de pegar em armas. A batalha está em seu sangue. Às vezes, você se pega realizando reflexivamente os exercícios básicos de luta que aprendeu primeiro. Por fim, você coloca esse treinamento em prática no campo de batalha, protegendo o reino por meio da guerra."}
  ]

  def up do
    feats_values = @feats |> Enum.map(&"('#{&1}')") |> Enum.join(", ")
    execute "INSERT INTO ctps.feats (slug) VALUES #{feats_values}"

    bg_values =
      @backgrounds
      |> Enum.map(fn {slug, title, a1, a2, a3, gold, feat, desc} ->
        "('#{slug}', '#{escape(title)}', '#{escape(desc)}', '#{a1}', '#{a2}', '#{a3}', #{gold}, '#{feat}')"
      end)
      |> Enum.join(",\n  ")

    execute """
    INSERT INTO ctps.backgrounds
      (slug, title, description, attr_one, attr_two, attr_three, gold_option, feat_slug)
    VALUES
      #{bg_values}
    """
  end

  def down do
    slugs = @backgrounds |> Enum.map(fn {s, _, _, _, _, _, _, _} -> "'#{s}'" end) |> Enum.join(",")
    execute "DELETE FROM ctps.backgrounds WHERE slug IN (#{slugs})"

    feat_slugs = @feats |> Enum.map(&"'#{&1}'") |> Enum.join(",")
    execute "DELETE FROM ctps.feats WHERE slug IN (#{feat_slugs})"
  end

  defp escape(str), do: String.replace(str, "'", "''")
end
