# StepOrbit

App para Apple Watch que muestra los pasos del día y una complicación circular para la esfera con el progreso hacia un objetivo diario opcional.

## Funcionalidades

- **Pasos de hoy** leídos de HealthKit, con actualización en directo mientras la app está en primer plano.
- **Objetivo diario** opcional (de 500 a 50.000 pasos) configurable con la Digital Crown.
- **Complicación `accessoryCircular`** con el número de pasos en formato compacto (p. ej. `8.5k`) y un anillo de progreso cuando hay objetivo.
- **Actualización en segundo plano**: un `HKObserverQuery` con *background delivery* recarga la complicación cuando llegan pasos nuevos.
- **Último valor conocido** guardado en el App Group, para que la complicación no muestre 0 cuando HealthKit no está accesible (reloj bloqueado).

## Requisitos

- Xcode 27 o posterior
- watchOS 11.6 o posterior
- Swift 6

## Estructura

```
Shared/                       Código compartido entre la app y el widget
├── HealthKit/                StepsRepository y su implementación con HealthKit
├── Models/                   DailySteps
└── Settings/                 StepGoalStore, StepsCache y constantes del App Group

StepOrbit Watch App/          App de watchOS
├── App/                      Punto de entrada
├── Presentation/
│   ├── ViewModels/           StepsViewModel
│   └── Views/                ContentView y StepGoalSettingsView
└── Resources/                Assets y cadenas localizadas

StepOrbitWidgets/             Extensión de WidgetKit (complicación)
```

La app y el widget comparten datos (objetivo y último recuento de pasos) a través del App Group `group.es.roltek.StepOrbit`.

## Puesta en marcha

1. Abre `StepOrbit.xcodeproj` en Xcode.
2. En *Signing & Capabilities* de los targets **StepOrbit Watch App** y **StepOrbitWidgetsExtension**, selecciona tu equipo de desarrollo.
3. Comprueba que ambos targets tienen las capacidades:
   - **HealthKit** (la app además con **Background Delivery**)
   - **App Groups** con `group.es.roltek.StepOrbit`
4. Ejecuta el esquema **StepOrbit Watch App** en un Apple Watch o en el simulador.
5. Concede acceso a los pasos cuando la app lo pida y añade la complicación StepOrbit a la esfera.

> En el simulador, HealthKit no genera pasos automáticamente: puedes añadirlos desde la app Salud del iPhone emparejado o con datos de prueba.

## Tests

```sh
xcodebuild test \
  -scheme "StepOrbit Watch App" \
  -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (46mm)'
```
