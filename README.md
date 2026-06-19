# 🍀 Trevo · Loterias

Aplicativo Flutter para consulta dos resultados das loterias brasileiras
(Mega-Sena, Lotofácil, Lotomania e Quina). Mostra o último resultado de
cada modalidade ou de um concurso específico, com as dezenas sorteadas,
o status de acúmulo e o prêmio estimado do próximo concurso.

Os dados vêm de uma API pública de loterias (veja [Créditos](#-créditos-e-api)).

## 📲 Como instalar no celular (Android)

1. Vá até a aba **[Releases](../../releases)** deste repositório.
2. Baixe o arquivo **`app-arm64-v8a-release.apk`** (serve para praticamente
   todos os celulares atuais).
3. Abra o arquivo baixado. O Android vai pedir para **permitir instalar de
   fontes desconhecidas** — confirme.
4. Pronto: o ícone do **Trevo** 🍀 aparece na tela do celular.

> Celular antigo (32 bits)? Baixe o `app-armeabi-v7a-release.apk`.

## ✨ Funcionalidades

- Consulta das modalidades Mega-Sena, Lotofácil, Lotomania e Quina
- Último resultado ou busca por número de concurso
- Dezenas em destaque com as cores oficiais de cada jogo
- Indicação de prêmio acumulado e valor estimado do próximo concurso
- Lista de premiações por faixa

## 🛠️ Rodando o projeto

```bash
flutter pub get
flutter run
```

### Gerar o APK de distribuição

```bash
flutter build apk --release --split-per-abi
# saída em build/app/outputs/flutter-apk/
```

## 📁 Estrutura

```
lib/
├── main.dart            # App + tema Material 3
├── config/              # Modalidades: cores, nomes e ícones
├── models/              # JogoLoteria e Premiacao (parsing do JSON)
├── services/            # Requisições HTTP à API
├── screens/             # Tela principal (navegação + FutureBuilder)
└── widgets/             # Componentes reutilizáveis (dezenas, cartões)
```

## 🙏 Créditos e API

Os resultados são obtidos da API pública **Loterias Caixa API**, criada por
**Guto Alves**:

- 📦 Repositório: <https://github.com/guto-alves/loterias-api>
- 🌐 Base da API: `https://loteriascaixa-api.herokuapp.com/api`
- 🔎 Endpoints usados:
  - `GET /{loteria}/latest` — último resultado da modalidade
  - `GET /{loteria}/{concurso}` — resultado de um concurso específico

Este app é um projeto independente e não possui vínculo oficial com a
Caixa Econômica Federal nem com o autor da API. Todo o crédito pelos dados
e pela API vai para o respectivo autor.

