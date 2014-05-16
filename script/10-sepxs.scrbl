#lang scribble/manual
@(require scribble/eval)
@(require "marburg-utils.rkt")
@(require (for-label lang/htdp-beginner))
@(require (for-label (except-in 2htdp/image image?)))
@(require (for-label 2htdp/universe))
@(require scriblib/footnote)

@title[#:version ""]{Quote und Unquote}

Listen spielen in funktionalen Sprachen eine wichtige Rolle, insbesondere
in der Familie von Sprachen, die von LISP abstammen (wie Racket und BSL).

Wenn man viel mit Listen arbeitet, ist es wichtig, eine effiziente Notation
dafür zu haben. Sie haben bereits die @racket[list] Funktion kennengelernt,
mit der man einfache Listen kompakt notieren kann.

Allerdings gibt es in BSL/ISL (und vielen anderen Sprachen) einen noch viel mächtigeren
Mechanismus, nämlich @racket[quote] und @racket[unquote]. Diesen Mechanismus
gibt es seit den 1950er Jahren in LISP, und noch heute eifern beispielsweise
Template Sprachen wie Java Server Pages oder PHP diesem Vorbild nach.

@section{Quote}
Das @racket[quote] Konstrukt dient als kompakte Notation für große und verschachtelte Listen. 
Beispielsweise können wir mit der Notation @racket[(quote (1 2 3))] die Liste @racket[(cons 1 (cons 2 (cons 3 empty)))] erzeugen.
Dies ist noch nicht besonders eindrucksvoll, denn der Effekt ist der gleiche wie

@ex[(list 1 2 3)]

Zunächst mal gibt es eine Abkürzung für das Schlüsselwort @racket[quote],
nämlich das Hochkomma, '.

@ex['(1 2 3)]

@ex['("a" "b" "c")]

@ex['(5 "xx")]

Bis jetzt sieht @racket[quote] damit wie eine minimale Verbesserung der @racket[list]
Funktion aus. Dies ändert sich, wenn wir damit verschachtelte Listen, also Bäume, erzeugen.

@ex['(("a" 1) ("b" 2) ("c" 3))]

Wir können also mit @racket[quote] auch sehr einfach verschachtelte Listen erzeugen,
und zwar mit minimalem syntaktischem Aufwand.

Die Bedeutung von @racket[quote] ist über eine rekursive syntaktische Transformation definiert.

@itemlist[
  @item{        
    @racket[(quote (e-1 ... e-n))] wird transformiert zu @racket[(list (quote e-1) ... (quote e-n))].
    Die Transformation wird rekursiv auf die erzeugten Unterausdrücke @racket[(quote e-1)] usw. angewendet.}
  @item{Wenn @racket[l] ein Literal (eine Zahl, ein String, ein Wahrheitswert@note{Aus komplizierten Gründen, die
        hier nicht relevant sind, müssen Sie die Syntax @racket[#t] und @racket[#f] für die Wahrheitswerte verwenden,
        wenn Sie sie quoten wollen; bei @racket[true] und @racket[false] erhalten Sie ein Symbol.}, oder ein Bild)
              ist, dann wird @racket[(quote l)] transformiert zu @racket[l].}
  @item{Wenn @racket[n] ein Name/Bezeichner ist, dann wird @racket[(quote n)] transformiert zum @italic{Symbol} @racket['n].}]

Ignorieren Sie eine Sekunde die dritte Regel und betrachten wir den Ausdruck @racket['(1 (2 3))].
Gemäß der ersten Regel wird dieser Ausdruck im ersten Schritt transformiert zu @racket[(list '1 '(2 3))].
Gemäß der zweiten Regel wird der Unterausdruck @racket['1] zu @racket[1] und gemäß der Anwendung der ersten
Regel wird aus dem Unterausdruck @racket['(2 3)] im nächsten Schritt @racket[(list '2 '3)]. Gemäß der zweiten
Regel wird dieser Ausdruck wiederum transformiert zu @racket[(list 2 3)]. Insgesamt erhalten wir also das Ergebnis @racket[(list 1 (list 2 3))].

Sie sehen, dass man mit @racket[quote] sehr effizient Listen erzeugen kann. Vielleicht fragen Sie sich,
wieso wir nicht gleich von Anfang an @racket[quote] verwendet haben. Der Grund dafür ist, dass diese bequemen Wege,
Listen zu erzeugen, verbergen, welche Struktur Listen haben. Insbesondere sollten Sie beim Entwurf von Programmen (und der Anwendung
des Entwurfsrezepts) stehts vor Augen haben, dass Listen aus @racket[cons] und @racket[empty] zusammengesetzt sind.

@section{Symbole}
Symbole sind eine Art von Werten die Sie bisher noch nicht kennen. Symbole dienen zur Repräsentation symbolischer Daten.
Symbole sind verwandt mit Strings; statt durch Anführungszeichen vorne und hinten wie bei einem String, 
@racket["Dies ist ein String"], werden Symbole durch ein einfaches Hochkomma gekennzeichnet: @racket['dies-ist-ein-Symbol].
Symbole haben die gleiche Syntax wie Namen/Bezeichner, daher sind beispielsweise Leerzeichen nicht erlaubt.

Im Unterschied zu Strings sind Symbole nicht dazu gedacht, Texte zu repräsentieren. Man kann beispielsweise nicht (direkt) Symbole
konkatenieren. Es gibt nur eine wichtige Operation für Symbole, nämlich der Vergleich von Symbolen mittels @racket[symbol=?].

@ex[(symbol=? 'x 'x)]

@ex[(symbol=? 'x 'y)]

@section{Quasiquote und Unquote}

Der @racket[quote] Mechanismus birgt noch eine weitere Überraschung.
Betrachten Sie das folgende Programm:

@racketblock[
(define x 3)
(define y '(1 2 x 4))
]             

Welchen Wert hat @racket[y] nach Auswertung dieses Programms? Wenn Sie die Regeln oben anwenden, sehen Sie, dass nicht etwa @racket[(list 1 2 3 4)]
sondern @racket[(list 1 2 'x 4)] herauskommt. Aus dem Bezeichner @racket[x] wird also das @italic{Symbol} @racket['x].

Betrachten wir noch ein weiteres Beispiel:

@ex['(1 2 (+ 3 4))]

Wer das Ergebnis @racket[(list 1 2 7)] erwartet hat, wird enttäuscht. Die Anwendung der Transformationsregeln ergibt das Ergebnis:
@racket[(list 1 2 (list '+ 3 4))]. Aus dem Bezeichner @racket[+] wird das Symbol @racket['+]. Das Symbol @racket['+] 
hat keine direkte Beziehung zur Additionsfunktion, genau wie das Symbol @racket['x] in dem Beispiel oben keine direkte
Beziehung zum Konstantennamen @racket[x] hat.

Was ist aber, wenn Sie Teile der (verschachtelten) Liste doch berechnen wollen?

Betrachten wir als Beispiel die folgende Funktion:

@#reader scribble/comment-reader
(racketblock
; Number -> (List-of Number)
; given n, generates the list ((1 2) (m 4)) where m is n+1
(check-expect (some-list 2) (list (list 1 2) (list 3 4)))
(check-expect (some-list 11) (list (list 1 2) (list 12 4)))
(define (some-list n) ...)
)

Eine naive Implementation wäre:

@block[
(define (some-list n) '((1 2) ((+ n 1) 4)))]

Aber natürlich funktioniert diese Funktion nicht wie gewünscht:

@ex[(some-list 2)]

Für solche Fälle bietet sich @racket[quasiquote] an. Das @racket[quasiquote]
Konstrukt verhält sich zunächst mal wie @racket[quote],ausser dass es
statt mit einem geraden Hochkomma, ', mit einem schrägen Hochkomma, `,
abgekürzt wird:

@ex[`(1 2 3)]
@ex[`(a ("b" 5) 77)]

Das besondere an @racket[quasiquote] ist, dass man damit innerhalb eines
gequoteten Bereichs zurückspringen kann in die Programmiersprache. Diese
Möglichkeit nennt sich "unquote" und wird durch das @racket[unquote] Konstrukt
unterstützt. Auch @racket[unquote] hat eine Abkürzung, nämlich das Komma-Zeichen.

@ex[`(1 2 ,(+ 3 4))]

Mit Hilfe von @racket[quasiquote] können wir nun auch unser Beispiel von oben korrekt implementieren.

@block[
(define (some-list-v2 n) `((1 2) (,(+ n 1) 4)))]

@ex[(some-list-v2 2)]

Die Regeln zur Transformation von @racket[quasiquote] sind genau wie die von @racket[quote] mit
einem zusätzlichen Fall: Wenn @racket[quasiquote] auf ein @racket[unquote] trifft, neutralisieren
sich beide. Ein Ausdruck wie @racket[`( ,e)] wird also transformiert zu @racket[e].

@section{S-Expressions}

@section{Anwendungsbeispiel: Dynamische Webseiten}

