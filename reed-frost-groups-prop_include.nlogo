__includes["calculations.nls" "wire.nls" "smallworld.nls" "normalDistribution.nls" "checkTurtles.nls" "checkTurtles2.nls"]

extensions [ table]

breed [ infants infant] ;; 0-4
breed [ youths youth] ;; 5-14
breed [ adults adult] ;; 15-44
breed [elders elder] ;; >45

turtles-own
[
  infected?
  susceptible?
  removed?
  preinfectious?
  asymptomatic?
  moderate?
  severe?
  preinfectious-timer ;; number of ticks since turtle become pre-infected
  infected-timer ;;number of ticks since turtle become infected
  lambda
  distance-from-other-turtles ;; used in finding the average path length
  infected-neighbours
  node-clustering-coefficient ;;used in finding the clustering coefficient

  ]

links-own
[
 rewired?
]

globals
[
  infected-nei-infant
  infected-nei-youth
  infected-nei-adult
  infected-nei-elder
  infected-2
  infinity
  average-path-length
  number-rewired
  p
  num-infected
  k-nei
  ce
  totalNodes
   infant-degree
  youth-degree
  adult-degree
  elder-degree
  ;;severity
  movenode1
  movenode2
  nei-node2
  clustering-coefficient ;; used in finding the clustering coefficient
  clusteringMetric ;; used in calculating small world ness
  pathMetric ;; used in calculating small world ness
  smallWorldNess ;; used in calculating small world ness
  severe-recover-delay ;; severe cases can have a longer recovery = recover-delay + extra delay

  severityRandom ;; number used to determine which category of severity an individual goes in to
  counter ;;counter
  calcAvgDegree

  contact ;; table with contact rates between age groups

]

to setup
  clear-all


  set infinity 99999  ;; just an arbitrary choice for a large number
                    ;;set-default-shape turtles "die 1"

set totalNodes Number-0-4 + Number-5-14 + Number-15-44 + Number-45


set infant-degree (average-degree * relative0-4)
set youth-degree (average-degree * relative5-14)
set adult-degree (average-degree * relative15-44)
set elder-degree (average-degree * relative45)

set severe-recover-delay (recovery-delay + severe-extra-delay)



show "here"
make-turtles
show"there"
let success? false
let SWsuccess? false

while [not SWsuccess?]
[
  ;;show success?
  while [not success? ]
  [
    wire-them
    set success? do-calculations

  ]
  rewire-all
 ;; check-turtles

    find-clustering-coefficient
    find-small-world-ness
    if smallWorldNess > 1
    [
      set SWsuccess? true
    ]
]

;;set initial number of adults to be infected
;; change adults to turtles to select from entire population.
  ask n-of initial-infected adults
  [
    set-infected
  ]

  set ce 2
  set p ce / totalNodes






  reset-ticks
end




to make-turtles

  create-infants Number-0-4[
    setxy( random-xcor * 0.95) (random-ycor * 0.95)
    set-susceptible
    set shape "die 1"
  ]
   create-youths Number-5-14[
    setxy( random-xcor * 0.95) (random-ycor * 0.95)
    set-susceptible
    set shape "die 2"
  ]
   create-adults Number-15-44[
    setxy( random-xcor * 0.95) (random-ycor * 0.95)
    set-susceptible
    set shape "die 3"
  ]
   create-elders Number-45[
    setxy( random-xcor * 0.95) (random-ycor * 0.95)
    set-susceptible
    set shape "die 4"

  ]


  ;;set tutles to form a circle
 ;; layout-circle ( turtles) max-pxcor - 1

end

to go
  ;;show "go"

;;show count turtles with [infected?]
;;show count turtles with [susceptible?]

;;stopping condition. If there are no infected or preinfectious turtles, then stop
if (count turtles with [infected?] = 0) and (count turtles with [preinfectious?] = 0)
[
  stop
]
;; check preinfectious turtles
;; increment timer and if timer is greater than infection-delay, move to infected
ask turtles with [ preinfectious?]
  [
    set preinfectious-timer preinfectious-timer + 1
    if preinfectious-timer > infect-delay
    [
      set-infected
    ]
  ]


;; increment and check timer on infected turtles
;; if above recovery delay move to recovered
ask turtles with [infected?]
  [
    set infected-timer infected-timer + 1
    if infected-timer > recovery-delay and severe? = false
    [
      set-removed
    ]
    if infected-timer > severe-recover-delay and severe? = true
      [
        set-removed
      ]
  ]

  spread-virus
  tick
end


to make-edge [node1 node2]
  ask node1 [create-link-with node2
    [
      set rewired? false
    ]
  ]

end

to setup-links
  let num-links (average-degree * totalNodes) / 2
  while[ count links < num-links]
  [
    ask one-of turtles
    [
      let choice (min-one-of (other turtles with [not link-neighbor? myself])
        [distance myself])
      if choice != nobody [ create-link-with choice]
    ]
  ]
  repeat 10
  [
    layout-spring turtles links 0.3 (world-width / (sqrt totalNodes)) 1
  ]

end

to set-susceptible ;; turtle procedure
  ;;change turtle to susceptible state
  set infected? false
  set removed? false
  set preinfectious? false
  set susceptible? true
   set asymptomatic? false
  set moderate? false
  set severe? false
  set color blue
  set infected-timer 0
  set preinfectious-timer 0

end

to set-infected ;;turtle procedure
  ;; procedure to change a turtles state to infected
  ;; set infected to true and removed, preinfectious and susceptible to false
  ;; reset infected-timer
  ;;

  set infected? true
  set removed? false
  set preinfectious? false
  set susceptible? false
  set infected-timer 0
 ;; set color red

 pickSeverity



end

to set-preinfectious ;; turtle procedure
  ;;move turtle to preinfected state
  ;;from susceptible
  set infected? false
  set removed? false
  set preinfectious? true
  set susceptible? false
  set preinfectious-timer 0
  set color yellow
end

to set-removed ;; turtle procedure
  ;;move turtle to recovered/removed state

  set infected? false
  set removed? true
  set preinfectious? false
  set susceptible? false
  set asymptomatic? false
  set moderate? false
  set severe? false
  set color green
end

to spread-virus
  ;;show "spread-virus"
  ask turtles with [infected?]
  [
    ask link-neighbors with [susceptible?]
    [
     ;; show count link-neighbors with [breed = infants and infected?]
       ;; count the number of neighbour which are infected and what breed they are
    set infected-2 count link-neighbors with [infected?]
    set infected-nei-infant count link-neighbors with [breed = infants and infected?]
    set infected-nei-youth count link-neighbors with [breed = youths and infected?]
    set infected-nei-adult count link-neighbors with [breed = adults and infected?]
    set infected-nei-elder  count link-neighbors with [breed = elders and infected?]

   ;; show "links"
   ;; show infected-neighbours
   ;; show infected-nei-infant
   ;; show infected-nei-youth
   ;; show infected-nei-adult
   ;; show infected-nei-elder
;;    show count link-neighbors with [breed = infants and infected?]
  ;;  show count link-neighbors with [breed = youths and infected?]
    ;;show count link-neighbors with [breed = adults and infected?]
    ;;show count link-neighbors with [breed = elders and infected?]
    ;;show count link-neighbors with [infected?]

      set infected-neighbours count link-neighbors with [infected?]
      ;;show "Infected-Neighbours"
      ;;show infected-neighbours
      ;;show infected-2
      ask link-neighbors with [infected?]
      [
       ;; show count infants
       ;; show count turtles with [ breed = infants]
      ]

    ;;show count infants  link-neighbors with [infected?]
    ;;  set num-infected count turtles with [infected?]

    ;;formula using total number of infected
    ;; set lambda (1 - ( 1 - p ) ^ num-infected )
    ;; formula using infected number of contacts
    set lambda (1 - ( 1 - infect-prob) ^ infected-neighbours )
    ;;show lambda
    ;; show lambda
    if random-float 1 < lambda
      [
        ;;  show "become pre-infectious"
        set-preinfectious]
    ]
  ]
end

to preinfectious-check

  ask turtles with [preinfectious? ]
  []

end
@#$#@#$#@
GRAPHICS-WINDOW
190
4
687
502
-1
-1
14.82
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
19
16
82
49
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
120
19
183
52
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
16
63
188
96
average-degree
average-degree
2
100
14.0
2
1
NIL
HORIZONTAL

SLIDER
14
141
186
174
initial-infected
initial-infected
1
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
13
217
185
250
infect-delay
infect-delay
1
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
11
258
183
291
recovery-delay
recovery-delay
1
30
7.0
1
1
NIL
HORIZONTAL

PLOT
693
312
995
477
Plot
time
people
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"infected" 1.0 0 -2674135 true "" "plot (count turtles with [infected?])"
"preinfectious" 1.0 0 -1184463 true "" "plot(count turtles with [preinfectious?])"
"susceptible" 1.0 0 -13345367 true "" "plot(count turtles with [susceptible?])"
"removed" 1.0 0 -10899396 true "" "plot(count turtles with [removed?])"

SLIDER
16
102
188
135
rewiring-probability
rewiring-probability
0
1
0.16
0.01
1
NIL
HORIZONTAL

SLIDER
13
177
185
210
infect-prob
infect-prob
0
1
0.057
0.001
1
NIL
HORIZONTAL

MONITOR
870
10
935
55
% 0-4
Number-0-4 / totalNodes * 100
2
1
11

MONITOR
868
58
935
103
% 5-14
Number-5-14 / totalNodes * 100
2
1
11

MONITOR
869
108
933
153
% 15-44
Number-15-44 / totalNodes * 100
2
1
11

MONITOR
870
157
934
202
% 45+
Number-45 / totalNodes * 100
2
1
11

MONITOR
687
174
744
219
Total
count turtles
17
1
11

SLIDER
690
10
862
43
Number-0-4
Number-0-4
0
1000
38.0
1
1
NIL
HORIZONTAL

SLIDER
693
48
865
81
Number-5-14
Number-5-14
0
1000
32.0
1
1
NIL
HORIZONTAL

SLIDER
689
87
861
120
Number-15-44
Number-15-44
0
1000
13.0
1
1
NIL
HORIZONTAL

SLIDER
688
135
860
168
Number-45
Number-45
0
1000
13.0
1
1
NIL
HORIZONTAL

SLIDER
977
19
1149
52
relative0-4
relative0-4
0
2
1.0
0.001
1
NIL
HORIZONTAL

SLIDER
976
53
1148
86
relative5-14
relative5-14
0
3
1.575
0.001
1
NIL
HORIZONTAL

SLIDER
974
91
1146
124
relative15-44
relative15-44
0
3
1.49
0.001
1
NIL
HORIZONTAL

SLIDER
979
129
1151
162
relative45
relative45
0
3
1.14
0.001
1
NIL
HORIZONTAL

INPUTBOX
979
172
1050
232
erCC
0.1014
1
0
Number

INPUTBOX
1063
174
1127
234
erPath
2.2492
1
0
Number

SLIDER
12
301
184
334
severe-extra-delay
severe-extra-delay
1
100
2.0
1
1
NIL
HORIZONTAL

SLIDER
977
244
1149
277
severityMean
severityMean
0
20
5.0
0.001
1
NIL
HORIZONTAL

SLIDER
977
277
1149
310
severitySD
severitySD
0
20
2.0
0.001
1
NIL
HORIZONTAL

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

die 1
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 129 129 42

die 2
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 189 189 42

die 3
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 129 129 42
Circle -16777216 true false 189 189 42

die 4
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 69 189 42
Circle -16777216 true false 189 69 42
Circle -16777216 true false 189 189 42

die 5
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 69 69 42
Circle -16777216 true false 129 129 42
Circle -16777216 true false 69 189 42
Circle -16777216 true false 189 69 42
Circle -16777216 true false 189 189 42

die 6
false
0
Rectangle -7500403 true true 45 45 255 255
Circle -16777216 true false 84 69 42
Circle -16777216 true false 84 129 42
Circle -16777216 true false 84 189 42
Circle -16777216 true false 174 69 42
Circle -16777216 true false 174 129 42
Circle -16777216 true false 174 189 42

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
NetLogo 6.0
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
