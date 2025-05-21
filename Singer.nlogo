extensions [csv]

globals [
  consensus-utility      ; Комплексная полезность по текущему консенсусу
  ethical-compliance     ; Уровень соответствия этическим нормам (0-100%)
  adaptation-history     ; История адаптаций системы [ [tick param value] ... ]
  simulation-step
  data-threshold
  avg-wellbeing         ; Среднее благополучие агентов
  success-rate
  migration-count
  zone-centers
  max-ticks
  ticks-to-full-success
  current-success-count
  all-achieved?
  perspectives         ; Список учитываемых перспектив [ [name weight] ... ]
  ethical-constraints  ; Этические ограничения [ [type condition] ... ]
]

turtles-own [
  multi-criteria-data  ; Данные по нескольким критериям [ [criterion value] ... ]
  current-priorities   ; Текущие приоритеты агента [ [criterion weight] ... ]
  value-system         ; Система ценностей агента [ [value weight] ... ]
  adaptation-strategy  ; Стратегия адаптации агента
  wellbeing            ; Уровень благополучия (0-100)
  moved?
  decision-history     ; История решений [ [tick decision params] ... ]
]

patches-own [
  multi-criteria-values  ; Значения по критериям [ [criterion value] ... ]
  ethical-valid?         ; Соответствие этическим нормам
  zone-quality
]

to setup
  clear-all
  set simulation-step 0
  set data-threshold 70
  set migration-count 0
  set max-ticks 10000
  set ticks-to-full-success 0
  set current-success-count 0
  set all-achieved? false
  set adaptation-history []

  ; Инициализация перспектив (пример)
  set perspectives [
    ["efficiency" 0.3]
    ["safety" 0.4]
    ["fairness" 0.3]
  ]

  ; Этические ограничения (пример)
  set ethical-constraints [
    ["no_harm" "wellbeing > 30"]
    ["fair_distribution" "variance wellbeing < 50"]
  ]

  ; Создаем центры зон (как в оригинале)
  set zone-centers []
  repeat random 3 + 2 [
    set zone-centers lput
      list (random-xcor * 0.8) (random-ycor * 0.8)
      zone-centers
  ]

  setup-zones  ; Инициализация зон (как в оригинале)

  ; Создаем агентов с многокритериальными параметрами
  create-turtles 150 [
    set shape "person"
    set color blue
    set size 1.5
    setxy random-xcor random-ycor

    ; Инициализация многокритериальных данных
    set multi-criteria-data [
      ["comfort" 0]
      ["safety" 0]
      ["access" 0]
    ]

    ; Инициализация приоритетов (случайные веса)
    set current-priorities map [ [c] ->
      list (first c) (0.2 + random-float 0.8)
    ] perspectives

    ; Нормализация весов
    let total sum map [ [p] -> last p ] current-priorities
    set current-priorities map [ [p] ->
      list (first p) ((last p) / total)
    ] current-priorities

    ; Система ценностей (пример)
    set value-system [
      ["autonomy" 0.5]
      ["cooperation" 0.3]
      ["growth" 0.2]
    ]

    ; Стратегия адаптации (1-консервативная, 2-адаптивная, 3-инновационная)
    set adaptation-strategy 1 + random 3

    set wellbeing 0
    set moved? false
    set decision-history []

    update-wellbeing
  ]

  setup-custom-plots
  reset-ticks
end

to setup-zones
  ; (как в оригинале, но добавляем многокритериальность)
  ask patches [
    set zone-quality 30
    set ethical-valid? true
    set multi-criteria-values [
      ["comfort" 30]
      ["safety" 50]
      ["access" 40]
    ]
  ]

  foreach zone-centers [
    [center] ->
    let center-x first center
    let center-y last center

    ask patches with [distancexy center-x center-y <= 7] [
      let dist distancexy center-x center-y
      set zone-quality max (list zone-quality (80 - dist * 3))

      ; Обновляем многокритериальные значения
      set multi-criteria-values [
        (list "comfort" (80 - (dist * 3)))
        (list "safety" (70 - (dist * 2)))
        (list "access" (90 - (dist * 4)))
      ]
   ]

    ask patches with [distancexy center-x center-y > 7 and distancexy center-x center-y <= 10] [
      set zone-quality 10
      set multi-criteria-values [
        ["comfort" 10]
        ["safety" 20]
        ["access" 15]
      ]
    ]
  ]

  ; Визуализация
  ask patches [
    ifelse zone-quality > 50 [
      set pcolor scale-color green zone-quality 50 80
    ] [
      set pcolor scale-color red zone-quality 0 50
    ]
  ]
end

to update-wellbeing  ; turtle procedure
  ; Комплексный расчет благополучия на основе критериев и ценностей
  let total-wellbeing 0
  let total-weight 0

  foreach current-priorities [
    [p] ->
    let criterion first p
    let weight last p
    let value get-criterion-value criterion

    ; Учитываем соответствие ценности
    let value-match get-value-match criterion
    set total-wellbeing total-wellbeing + (value * weight * value-match)
    set total-weight total-weight + (weight * value-match)
  ]

  set wellbeing ifelse-value (total-weight > 0)
    [ total-wellbeing / total-weight ]
    [ 0 ]
end

to get-criterion-value [ criterion ]  ; turtle procedure
  ; Получаем значение критерия из текущего патча
  let patch-data [multi-criteria-values] of patch-here
  let item filter [ [item] -> first item = criterion ] patch-data
  ifelse empty? item [ 0 ] [ last first item ]
end

to get-value-match [ criterion ]  ; turtle procedure
  ; Определяем насколько критерий соответствует ценностям агента
  let value-score 0
  if criterion = "comfort" [ set value-score 0.7 ]  ; пример
  if criterion = "safety" [ set value-score 0.9 ]
  if criterion = "access" [ set value-score 0.5 ]
  value-score
end

to go
  set simulation-step simulation-step + 1

  ask turtles [
    set moved? false
    refine-priorities  ; Уточнение приоритетов
  ]

  ; Динамика среды (каждые 20 шагов)
  if ticks mod 20 = 0 [
    evolve-zones
    adapt-ethical-constraints
  ]

  ; Процессы агентов
  ask turtles [
    gather-multi-criteria-data
    analyze-complex-utility
    ethical-validation
    adaptive-move
    update-wellbeing
    record-decision
  ]

  ; Системные процессы
  calculate-system-utility
  check-ethical-compliance
  update-adaptation-history
  calculate-metrics
  update-custom-plots

  ; Вывод в командную строку
  if (ticks mod 10 = 0) [
    output-print (word "Тик: " ticks ", Благополучие: " avg-wellbeing ", Этичность: " ethical-compliance)
  ]

  ; Сообщение при полном достижении
  if (current-success-count = count turtles) and (all-achieved? = false) [
    set all-achieved? true
    set ticks-to-full-success ticks
    output-print (word "Оптимальное состояние достигнуто на тике: " ticks)
  ]

  tick
end

to refine-priorities  ; turtle procedure
  ; Адаптивное уточнение приоритетов на основе опыта
  if random 100 < 20 [  ; 20% chance to adjust priorities
    set current-priorities map [
      [p] ->
      let new-weight (last p) * (0.9 + random-float 0.2)  ; случайное изменение
      list (first p) new-weight
    ] current-priorities

    ; Нормализация весов
    let total sum map [ [p] -> last p ] current-priorities
    set current-priorities map [
      [p] -> list (first p) ((last p) / total)
    ] current-priorities
  ]
end

to gather-multi-criteria-data  ; turtle procedure
  ; Сбор данных по нескольким критериям
  let nearby-turtles other turtles in-radius 5
  let nearby-patches patches in-radius 3

  ; Обновляем данные на основе локальной информации
  set multi-criteria-data map [
    [criterion-data] ->
    let criterion first criterion-data
    let new-value 0
    let count 0

    ; Учитываем данные из патчей
    ask nearby-patches [
      let patch-data [multi-criteria-values] of self
      let item filter [ [item] -> first item = criterion ] patch-data
      if not empty? item [
        set new-value new-value + last first item
        set count count + 1
      ]
    ]

    ; Учитываем данные от других агентов
    ask nearby-turtles [
      let turtle-data [multi-criteria-data] of self
      let item filter [ [item] -> first item = criterion ] turtle-data
      if not empty? item [
        set new-value new-value + last first item
        set count count + 1
      ]
    ]

    ; Усредненное значение
    ifelse count > 0 [
      list criterion (new-value / count)
    ] [
      criterion-data  ; оставляем старое значение если нет новых данных
    ]
  ] multi-criteria-data
end

to analyze-complex-utility  ; turtle procedure
  ; Расчет комплексной полезности для принятия решений
  let utility 0
  let total-weight 0

  foreach current-priorities [
    [p] ->
    let criterion first p
    let weight last p
    let value get-criterion-value criterion

    ; Добавляем взвешенную полезность
    set utility utility + (value * weight)
    set total-weight total-weight + weight
  ]

  ; Учитываем адаптационную стратегию
  if adaptation-strategy = 1 [ set utility utility * 0.9 ]  ; консервативная
  if adaptation-strategy = 3 [ set utility utility * 1.1 ]  ; инновационная

  ; Записываем полезность как временное свойство
  set current-opinion utility / total-weight
end

to ethical-validation  ; turtle procedure
  ; Проверка решений на соответствие этическим нормам
  let ethical-ok true

  foreach ethical-constraints [
    [constraint] ->
    let condition last constraint
    if not run-result condition [ set ethical-ok false ]
  ]

  ; Если нарушены этические нормы - корректируем решение
  if not ethical-ok [
    set current-opinion current-opinion * 0.7  ; снижаем полезность
    set wellbeing wellbeing - 5  ; штраф за неэтичность
  ]
end

to adaptive-move  ; turtle procedure
  ; Адаптивное перемещение с учетом стратегии
  if not moved? and (wellbeing < 50 or (random-float 1.0 < 0.15)) [
    let radius 3
    if adaptation-strategy = 2 [ set radius 5 ]  ; адаптивные агенты смотрят дальше

    let candidates patches in-radius radius with [ethical-valid?]

    if any? candidates [
      ; Выбираем лучший патч по комплексной оценке
      let target max-one-of candidates [
        [multi-criteria-utility [current-priorities] of myself]
      ]

      if target != nobody [
        face target
        fd 1
        set moved? true
        set migration-count migration-count + 1
      ]
    ]
  ]
end

to multi-criteria-utility [ priorities ]  ; patch procedure
  ; Расчет полезности патча для агента с заданными приоритетами
  let utility 0
  let total-weight 0

  foreach priorities [
    [p] ->
    let criterion first p
    let weight last p
    let item filter [ [item] -> first item = criterion ] multi-criteria-values

    if not empty? item [
      set utility utility + (last first item * weight)
      set total-weight total-weight + weight
    ]
  ]

  ifelse total-weight > 0 [ utility / total-weight ] [ 0 ]
end

to record-decision  ; turtle procedure
  ; Запись истории решений
  set decision-history lput
    (list ticks
          (word "move-to " pxcor " " pycor)
          (list wellbeing current-opinion))
    decision-history
end

to calculate-system-utility
  ; Расчет комплексной полезности системы
  let total-utility 0
  let agent-count count turtles

  if agent-count > 0 [
    ask turtles [
      set total-utility total-utility + current-opinion
    ]
    set consensus-utility total-utility / agent-count
  ]
end

to check-ethical-compliance
  ; Проверка соответствия системы этическим нормам
  let compliance 100  ; начальное значение

  foreach ethical-constraints [
    [constraint] ->
    let condition last constraint
    if not run-result condition [
      set compliance compliance - 30  ; штраф за нарушение
    ]
  ]

  set ethical-compliance max list 0 compliance
end

to update-adaptation-history
  ; Запись параметров адаптации системы
  set adaptation-history lput
    (list ticks consensus-utility ethical-compliance avg-wellbeing)
    adaptation-history
end

to calculate-metrics
  ; Считаем агентов с высоким благополучием (>60)
  set current-success-count count turtles with [wellbeing > 60]
  set avg-wellbeing mean [wellbeing] of turtles

  ; Проверяем полное достижение целей
  if (current-success-count = count turtles) and not all-achieved? [
    set ticks-to-full-success ticks
    set all-achieved? true
  ]
end

to setup-custom-plots
  ; Настройка графиков для мониторинга системы
  set-current-plot "Благополучие системы"
  set-plot-x-range 0 max-ticks
  set-plot-y-range 0 100

  create-temporary-plot-pen "Среднее благополучие"
  set-plot-pen-mode 1
  set-plot-pen-color green

  create-temporary-plot-pen "Этическое соответствие"
  set-plot-pen-mode 1
  set-plot-pen-color blue

  create-temporary-plot-pen "Комплексная полезность"
  set-plot-pen-mode 1
  set-plot-pen-color red
end

to update-custom-plots
  ; Обновление графиков
  set-current-plot "Благополучие системы"
  plot avg-wellbeing
  plot ethical-compliance
  plot consensus-utility
end

to adapt-ethical-constraints
  ; Адаптация этических ограничений (пример)
  if ticks mod 100 = 0 [
    ; Ослабляем ограничения если благополучие низкое
    if avg-wellbeing < 40 [
      set ethical-constraints map [
        [c] ->
        ifelse first c = "no_harm" [
          list "no_harm" "wellbeing > 20"  ; снижаем порог
        ] [
          c  ; оставляем без изменений
        ]
      ] ethical-constraints
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
