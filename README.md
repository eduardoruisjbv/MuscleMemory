# MuscleMemory

Addon para World of Warcraft Retail 12.1. Versão **0.7.0**, com editor em português e sem bibliotecas externas.

O MuscleMemory traduz a **finalidade principal de uso** de uma habilidade para a mesma posição de barra em outro personagem. Considera especialização, papel na rotação, frequência de uso, cooldown, cargas e condições como abates, além de tempo de lançamento e custo relativo ao recurso. Dois valores de recursos diferentes, como runas e fúria, não são comparados diretamente.

## Começar

1. Reinicie o WoW se ele já estava aberto quando o addon foi instalado. Ative **MuscleMemory** na lista de addons.
2. Entre no main, organize suas barras e execute `/mm`.
3. Clique em **Capturar barras deste personagem**. Isso salva uma referência fixa por personagem e especialização.
4. Entre no secundário, abra `/mm` e selecione a **classe main** e a **referência** capturada.
5. A classe secundária e a especialização começam com as do personagem atual. O mapa já aparece preenchido com sugestões automáticas.
6. Clique em **Aplicar sugestões** para usar o mapa. Se quiser revisar, abra **Editar equivalências** e ajuste por clique ou arraste. **Prévia** é opcional.
7. Escolha **Modo: equivalências entre personagens** ou **Modo: leveling por prioridade**. Para automatizar, marque **Automático** e confirme **Autorizar e ativar**. As autorizações antigas ficam desativadas nesta atualização.

A tela principal mostra uma tabela compacta de origem, função e destino. Buscas nas três colunas, filtros e listas para arrastar aparecem ao abrir **Editar equivalências**. **Usar sugestões** recupera o mapa automático e substitui as associações manuais deste par, sem alterar as barras até aplicar. A linha de equivalência destaca função, atalho capturado e habilidades associadas. Slots técnicos ficam nos tooltips. **Restaurar barras** desfaz a última aplicação; restaurar uma sugestão individual pelo botão direito modifica apenas a equivalência.

Botão direito no ícone de destino permite recuperar a sugestão automática ou excluir uma habilidade da tradução. Escolhas manuais são salvas por referência main, classe e especialização de destino. Alterar a seleção desativa a aplicação automática até você habilitá-la novamente.

## Montarias, utilitários e leveling (0.7.0)

- Montarias nativas, macros, itens e flyouts da origem entram na lista e nos filtros. Montarias recebem a função **viajar / voar / ir mais rápido**, conservando a escolha original. A disponibilidade é conferida no personagem atual; não há substituição aleatória de uma montaria indisponível.
- **Caminho de Gelo** (DK) e **Caminhar sobre a Água** (Xamã) receberam finalidade própria. **Brado de Batalha** continua como buff de grupo: caminhar na água e aumentar poder de ataque têm efeitos diferentes e podem ser associados manualmente se o jogador quiser usar uma tecla comum de preparação.
- Em **leveling por prioridade**, não é necessário capturar outro personagem. O grimório realmente aprendido e a especialização atual determinam as habilidades elegíveis. O modo organiza os ataques nas posições prioritárias, aloca novas habilidades e preserva posições existentes de utilitários, macros e itens. Montarias disponíveis seguem a referência selecionada, respeitando posições fixas e outras ações protegidas.
- Os padrões de 18 especializações têm ordem explícita de barras; as demais usam a função da habilidade como fallback. Essa ordem é uma preferência de layout, não uma simulação de DPS nem uma previsão de qual habilidade lançar. A lista nativa de rotação assistida não é usada como ordem de prioridade.
- Abra **Editar equivalências** e use botão direito em uma habilidade para aumentar/diminuir prioridade, fixar sua posição atual ou excluir/reincluir na organização. **Restaurar prioridades padrão** fica no menu de modo. As preferências são individuais por personagem/especialização.
- O consentimento de leveling vale para o personagem e suas especializações, incluindo a progressão anterior à primeira especialização. A automação reage a login, nível, grimório, talentos e especialização, com eventos agrupados. Durante combate, cursor ocupado ou barra temporária, aguarda uma condição válida.
- O automático começa desligado e exige **Autorizar e ativar**. Trocar modo/referência ou desmarcar a opção desativa a automação. **Restaurar barras** também desativa o automático nas especializações do personagem. No automático, o backup é acumulado desde a primeira alteração da autorização na especialização atual; na aplicação manual, restaura a última aplicação. Feitiços que deixaram de estar disponíveis podem continuar pendentes no desfazer.
- A atualização adiciona arquivos Lua ao TOC: **feche e abra o WoW** para carregar todos os arquivos novos.

## Comandos

| Comando | Ação |
| --- | --- |
| `/mm` ou `/musclememory` | Abre/fecha o editor |
| `/mm capture` | Salva as barras atuais como referência |
| `/mm apply` | Aplica o mapa no personagem atual |
| `/mm undo` | Restaura o backup desta especialização e desativa o automático |

## Como as sugestões funcionam

O foco é automático: basta capturar o main uma vez. Personagens sem referência escolhida adotam a referência principal salva ou a captura mais recente de outro perfil. A edição e a prévia são opcionais. DK ↔ Guerreiro possui preferências iniciais por especialização, com alternativas quando um talento não está disponível.

- Perfis de habilidades selecionadas de 17 especializações nas 13 classes foram revisados com guias do Wowhead e do Icy Veins para o patch 12.1. Ritmo de uso e efeito sobre recurso/proc priorizam candidatos; a ausência de um perfil revisado ou diferenças de recurso não bloqueiam sugestões funcionais. Alternativas por hábito de uso aparecem como **Alternativa automática**, com as diferenças no tooltip. Explicações e fontes aparecem no tooltip. A cobertura exata está em [Rotações e fontes](docs/ROTACOES-E-FONTES.md).
- O Single-Button Assistant nativo fornece participação na rotação assistida fora de combate. A ordem da lista não determina equivalências; habilidade desconhecida não recebe função só por estar nela. O botão assistido tem categoria própria, quando encontrado no grimório, e a ausência da API não impede o uso do addon.
- O grimório ativo fornece as habilidades realmente disponíveis, considerando talentos e especialização.
- Uma revisão de habilidades principais das 13 classes separa a finalidade principal dos efeitos secundários. O tooltip apresenta a descrição autoral, fontes, cooldown de referência, cargas e condições de uso. A cobertura e as ressalvas estão em [Auditoria das habilidades](docs/AUDITORIA-HABILIDADES.md).
- **Cópia antes da comparação:** mesmo ID, ID base/substituição ou mesmo nome na mesma classe recebe prioridade máxima. IDs diferentes da barra e do grimório são resolvidos na referência. A mesma habilidade pode preencher seus slots originais mesmo quando aparece com mais de um ID; a UI indica **Cópia automática**. O grimório ativo determina qual ID pode ser colocado no destino.
- **Funções secundárias participam do ranking:** recurso/proc, cura adicional, controle, dano em área, imunidade a controle e interações com a janela ofensiva ajudam a ordenar alternativas. O tooltip informa funções secundárias não confirmadas na alternativa e diferenças de ritmo da rotação. Dano em área e controle coletivo permanecem dimensões distintas. As regras e os exemplos estão em [Principal e secundárias](docs/PRINCIPAL-E-SECUNDARIAS.md).
- **Botão reservado de sobrevivência:** Pacto da Morte, Escudo Divino e Bloco de Gelo compartilham a decisão de sobreviver a uma emergência. Podem receber uma alternativa automática entre classes, mantendo o mecanismo principal explícito: cura e imunidade têm efeitos diferentes. Imunidade não recupera vida; Bloco de Gelo impede agir. CDs, restrições e efeitos adicionais aparecem no tooltip. Essa aproximação se limita a botões com intenção de emergência declarada; não transforma qualquer cura em imunidade ou qualquer defesa em último recurso.
- **Controle coletivo e explosão em área:** Saraivada Cegante é controle sem dano; Fúria da Serpe Gélida é dano em área na janela ofensiva com stun/lentidão adicionais. O motor compara o primeiro com controles coletivos e o segundo com ataques de área sob recarga. Diferenças como desorientação/medo/stun, quebra por dano e efeitos secundários são sinalizadas; controle de alvo único não substitui automaticamente controle coletivo.
- **Raciais compartilhadas:** a mesma habilidade aprendida no main e no destino tem prioridade máxima, mesmo em capturas antigas sem classificação. Will to Survive (59752) é uma saída de atordoamento. Raciais não são adicionadas a toda uma classe pelo catálogo: precisam constar no grimório atual ou em um personagem visitado. Entrar no destino confirma a disponibilidade real.
- **Sair de controle:** Fortitude Gélida é classificada principalmente como saída de atordoamento, mantendo redução de dano como efeito secundário no tooltip. Uma saída de medo não substitui automaticamente uma saída de stun. Forma Decadente e Raiva Incontrolada podem compartilhar a finalidade de sair de medo, com diferenças adicionais de controle sinalizadas.
- **Frequência de cura:** Golpe da Morte é cura/recuperação repetível por recurso. Ímpeto da Vitória tem recarga e reset por abate, enquanto Investida Vitoriosa depende de um abate recente. Esses botões não substituem automaticamente Golpe da Morte. Pacto da Morte → Ímpeto da Vitória é uma preferência para cura com cooldown: os valores nominais revisados de 120 e 25 segundos continuam distintos e aparecem como alternativa automática. Não se presume igual disponibilidade ou potência.
- Investida Vitoriosa também não substitui automaticamente Pacto da Morte: exigir um abate antes de curar é diferente de ter uma cura de emergência sob recarga. Se Ímpeto da Vitória não estiver aprendido, o addon preserva o botão sem inventar essa alternativa.
- Cooldown base e número de cargas são coletados fora de combate quando as APIs retornam valores públicos; recargas de cargas em andamento podem fornecer duração observada. A informação nominal revisada é usada quando não há valor estático utilizável. O motor não usa tempo restante de cooldown nem disponibilidade momentânea para decidir equivalências; uma habilidade pronta continua sendo um botão com recarga. Modificações de talentos que a API não expõe estaticamente continuam sendo uma limitação.
- Habilidades verificadas como removidas ou passivas não entram nas sugestões de botões ativos. Novos IDs revisados ampliam o catálogo; habilidades desconhecidas continuam disponíveis para edição manual.
- Um catálogo inicial identifica funções como geração de recurso, gasto principal, gasto em área, interrupção, defesa, mobilidade e cura para as 13 classes. Defesas também descrevem escola protegida, mecanismo, alvo, ritmo de uso e cobertura do efeito.
- Defesa física, defesa mágica e imunidade preservam escolas e alvos distintos. Dentro da mesma escola, alvo, ritmo e cobertura, mecanismos diferentes de defesa podem receber uma alternativa automática sinalizada. Efeitos mistos continuam representados individualmente. Cura pessoal/aliada, cura direta/periódica/em área, tipos de controle e mobilidade também refinam a compatibilidade.
- O mesmo feitiço pode mudar de função por especialização. Death Strike é tratado como gasto defensivo em Blood e cura nas especializações DPS.
- Habilidades com função e comportamento compatíveis recebem sugestões. As reservas de emergência declaradas e os controles coletivos admitem aproximações sinalizadas. As demais comparações preservam escola, alvo, cobertura e disponibilidade modelados. Tempo de lançamento e custo relativo refinam a escolha. Destinos automáticos são reservados por origem distinta; cópias da mesma habilidade com IDs diferentes preservam todos os slots correspondentes. Uma escolha manual também pode reutilizar um destino. Escolhas manuais de funções diferentes mostram um aviso e continuam sendo respeitadas.
- A alocação automática é gulosa, ordenada por compatibilidade e IDs para resultados estáveis; não busca uma solução global ótima.
- Habilidades desconhecidas são listadas com função estimada e não recebem equivalência automática por essa estimativa. A exceção é a mesma habilidade efetivamente disponível nos dois perfis; não é necessário estimar uma função para preservar seu próprio botão.
- **Não configurado** indica classificação insuficiente ou uma escolha pendente. **Sem equivalente direto no catálogo** indica uma fonte conhecida para a qual não há destino completamente compatível nos dados disponíveis. **Indisponível** indica que um destino manual salvo não está na lista atual. Esses estados não apagam ações da barra.
- O catálogo é uma base inicial de funções, não uma simulação completa das rotações. Talentos, mudanças do jogo e prioridades de cada jogador podem exigir ajustes.
- Para classes desconectadas, o editor combina o catálogo base e grimórios dos personagens já visitados. A disponibilidade real é conferida quando você entra no destino. Só é possível aplicar ao personagem e especialização atuais.

## Barras e restauração

O addon trabalha com slots Blizzard **1–72 e 145–180**, preservando o índice original do main. Isso inclui as páginas normais e barras adicionais. Páginas de formas/posturas, barras de veículo, possessão, override e extra action não são traduzidas. O addon não muda teclas: pressupõe que os personagens usem teclas equivalentes para os mesmos slots.

Capturas novas também guardam os atalhos reais das barras Blizzard e bindings de clique desses botões. A prévia mostra os atalhos atuais do destino. Se uma posição a alterar tiver uma tecla capturada sem correspondência no destino, a aplicação automática é desativada e informa o motivo; a aplicação manual continua disponível. Capturas antigas sem teclas mostram **Atalho não capturado** e precisam ser recapturadas para habilitar essa comparação. Páginas condicionais inativas não recebem atalhos inventados.

Na tradução, slots vazios, com feitiços ou montarias podem receber alterações. Macros, itens e flyouts diferentes nos destinos são preservados. Slots do main sem equivalência não são apagados. Montarias usam a escolha exata da origem, incluindo o botão de favoritas aleatórias; o addon não decide qual montaria você prefere. A coleção deve disponibilizar a mesma montaria para o personagem e ela precisa estar visível nos filtros para ser pega. Macros só são copiadas quando o destino já tem uma macro com conteúdo idêntico; o índice numérico da origem nunca é reutilizado. Capturas antigas de macros precisam ser refeitas para registrar o conteúdo. Itens utilitários são copiados quando disponíveis; flyouts ficam visíveis como pendências e não são traduzidos.

A aplicação é bloqueada durante combate ou barras temporárias. Eventos de talentos/especialização em combate são processados depois de sair dele. Cada aplicação guarda os slots anteriores antes de alterá-los. Se a API recusar uma mudança, o processo para e informa que `/mm undo` está disponível. Desfazer preserva slots que você editou depois; feitiços antigos que não podem mais ser colocados ficam pendentes na restauração. O histórico manual é da última aplicação; no automático, acumula a sessão de autorização por personagem/especialização.

## Limites desta versão

- Retail 12.1; Classic não foi implementado.
- Personagens visitados aparecem individualmente na origem, com nome, reino e especialização. Barras fora do automático são registradas após entrar e ao sair; capturas explícitas continuam fixas e têm precedência. Registros antigos sem barras aparecem como **sem captura**: entre no personagem e capture suas barras. O addon não lê barras de personagens desconectados diretamente do servidor. SavedVariables são compartilhadas pela mesma conta/instalação.
- Grimório de mascote, feitiços dentro de flyouts e barras personalizadas sem os slots Blizzard não são traduzidos. Macros são preservadas por conteúdo exato, sem interpretação ou criação de novas macros.
- O catálogo não cobre todas as habilidades, especializações recém-adicionadas ou substituições de talentos. Novas especializações do personagem atual são descobertas em tempo de execução; habilidades sem classificação ficam manuais.
- Perfis de efeitos representam a função base da habilidade. Modificações de talentos, exceções de encontros e diferenças PvP/PvE podem exigir ajustes manuais. O modelo não afirma equivalência de potência, duração ou percentual de redução.
- Não há análise de combate ou escolha de qual habilidade lançar. A automação organiza o layout fora de combate.
- O editor e as APIs protegidas ainda precisam de validação dentro do WoW. A verificação local usa LuaJIT e APIs simuladas; isso não comprova comportamento de frames, cursor, talentos e taint no cliente real.

## Instalação

Copie a pasta `MuscleMemory/` (a que contém `MuscleMemory.toc`) para `_retail_/Interface/AddOns/`. O conteúdo desse diretório deve ficar em `AddOns/MuscleMemory/`, sem uma pasta extra no meio.

Os dados ficam em `WTF/Account/<conta>/SavedVariables/MuscleMemory.lua` e não estão no código do addon.

## Desenvolvimento

| Arquivo | Responsabilidade |
| --- | --- |
| `MuscleMemory/Catalog.lua` | Classes e funções base por feitiço/especialização |
| `MuscleMemory/Rotations.lua` | Contextos revisados, fontes dos guias e participação na assistência nativa |
| `MuscleMemory/Purposes.lua` | Revisão das finalidades, cooldowns, cargas, condições e raciais |
| `MuscleMemory/Effects.lua` | Efeitos principais/secundários, controles coletivos e reservas de emergência |
| `MuscleMemory/FunctionModel.lua` | Regras de finalidade principal, frequência e metadados de recarga |
| `MuscleMemory/Engine.lua` | Compatibilidade, prioridades manuais e plano de alterações |
| `MuscleMemory/Core.lua` | Grimório, perfis, eventos, aplicação e restauração |
| `MuscleMemory/Actions.lua` | Montarias e ações utilitárias, identidade exata e referências visitadas |
| `MuscleMemory/Leveling.lua` | Prioridade de barras, posições fixas, progresso e consentimento |
| `MuscleMemory/UI.lua` | Editor, seleção de classes/especializações e arrastar habilidades |

Execute `luajit tests/run.lua` a partir deste diretório para as verificações locais. O roteiro de validação real está em `docs/VALIDACAO-NO-WOW.md`.

A versão 0.7.0 não teve testes executados nesta etapa. A compilação local confere a sintaxe Lua; a equivalência e o comportamento do addon ainda precisam ser validados dentro do WoW. Resultados de versões anteriores não validam as novas regras.

O desenho do menu está em `docs/UI-DESIGN.md` e as regras de comparação em `docs/CLASSIFICACAO.md`. Frames são reutilizados, o contexto de equivalências tem cache e a interface oculta não reconstrói listas. A animação de abertura dura 120 ms; não há atualização contínua por `OnUpdate`.

APIs consultadas no código da interface Blizzard distribuído no espelho [wow-ui-source](https://github.com/Gethe/wow-ui-source): [grimório](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua), [feitiços](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua), [especializações](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpecializationInfoDocumentation.lua) e [botões de ação](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ActionBar/Shared/ActionButton.lua).
