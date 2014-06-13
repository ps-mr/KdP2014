#lang scribble/manual
@(require scribble/eval)
@(require "marburg-utils.rkt")
@(require (for-label lang/htdp-advanced))
@(require (for-label (except-in 2htdp/image image?)))
@(require (for-label 2htdp/universe))
@(require scribble/bnf)
   
@title[#:version ""]{Pattern Matching}
Viele Funktionen konsumieren Daten, die einen algebraischen Datentyp haben, also eine Mischung aus
Summen- und Produkttypen (@secref{adts}). 

Häufig (und gemäß unseres Entwurfsrezepts) sehen solche Funktionen so aus, dass zunächst einmal unterschieden
wird, welche Alternative gerade vorliegt, und dann wird (ggf. in Hilfsfunktionen) auf die Komponenten
des in der Alternative vorliegenden Produkttypen zugegriffen.

Beispielsweise haben Funktionen, die Listen verarbeiten, typisch diese Struktur:
@racketblock[
(define (f l)
  (cond [(cons? l) (... (first l) ... (sum (rest l))...)]
        [(empty? l) ...]))]

Mit @italic{Pattern Matching} können solche Funktionen mit deutlich reduziertem Aufwand definiert werden.
Pattern Matching hat zwei Facetten: 1) Es definiert implizit eine Bedingung, analog zu den
Bedingungen in den @racket[cond] Klauseln oben. 2) Es definiert Namen, die statt der Projektionen
(@racket[(first l)] und @racket[(rest l)] im Beispiel) verwendet werden können.

@section{Pattern Matching in ASL}
Um Unterstützung für Pattern Matching zu bekommen, schalten wir nun auf die @italic{Advanced Student Language} (ASL)
um. In ASL gibt es zum Pattern Matching das @racket[match] Konstrukt.

Das folgende Beispiel zeigt, wie das @racket[match] Konstrukt verwendet werden kann.

@racketblock[
(define (f x)
    (match x
      [7 8]
      ["hey" "joe"]
      [(list 1 y 3) y]
      [(cons a (list 5 6)) (add1 a)]
      [(struct posn (5 5)) 42]
      [(struct posn (y y)) y]
      [(struct posn (y z)) (+ y z)]
      [(cons (struct posn (1 z)) y) z]))]               

Probieren Sie aus, was die Auswertung der folgenden Ausdrücke ergibt und versuchen Sie, die Ergebnisse zu verstehen:

@racketblock[
(f 7)
(f "hey")
(f (list 1 2 3))
(f (list 4 5 6))
(f (make-posn 5 5))
(f (make-posn 6 6))
(f (make-posn 5 6))
(f (list (make-posn 1 6) 7))]

Jede Klausel in einem @racket[match] Ausdruck beginnt mit einem Pattern. Ein Pattern kann ein Literal sein, wie
in den ersten beiden Klauseln (@racket[7] und @racket["hey"]). In diesem Fall ist das Pattern lediglich eine
implizite Bedingung: Wenn der Wert, der gematcht wird (im Beispiel @racket[x]), gleich dem Literal ist, dann ist der
Wert des Gesamtausdrucks der der rechten Seite der Klausel (analog zu @racket[cond]). 

Interessant wird Pattern Matching dadurch, dass auch auf Listen und andere algebraische Datentypen "gematcht" werden kann.
In den Pattern dürfen Namen vorkommen (wie das @racket[y] in @racket[(list 1 y 3)] ; diese Variablen sind im Unterschied zu Strukturnamen oder Literalen keine 
Bedingungen, sondern sie dienen zur Bindung der Namen an den entsprechenden Teil der Struktur.

Allerdings können Namen zur Bedingung werden, wenn sie mehrfach im Pattern vorkommen. Im Beispiel oben ist dies der Fall
im Pattern @racket[(struct posn (y y))]. Dieses Pattern matcht nur dann, wenn @racket[x] eine @racket[posn] ist und beide
Komponenten den gleichen Wert haben.

Falls mehrere Pattern gleichzeitig matchen, so "gewinnt" stets das erste Pattern, welches passt (analog dazu wie auch bei @racket[cond] stets
die erste Klausel, deren Kondition @racket[true] ergibt, "gewinnt". Daher ergibt beispielsweise @racket[(f (make-posn 5 5))]
im Beispiel das Ergebnis @racket[42] und nicht etwa @racket[5] oder @racket[10].

Das letzte Pattern, @racket[(cons (struct posn (1 z)) y)], illustriert, dass Patterns beliebig tief verschachtelt werden können.

Beispielsweise können wir mittels Pattern Matching die Funktion

@racketblock[
(define (person-has-ancestor p a)
  (cond [(person? p)
         (or
          (string=? (person-name p) a)
          (person-has-ancestor (person-father p) a)
          (person-has-ancestor (person-mother p) a))]
        [else false]))]

aus @secref{rekursivedatentypen} umschreiben zu:

@racketblock[
(define (person-has-ancestor p a)
  (match p 
    [(struct person (name father mother))
         (or
          (string=? name a)
          (person-has-ancestor father a)
          (person-has-ancestor mother a))]
    [else false]))]

@section{Pattern Matching formal}

Falls man einen Ausdruck der Form @racket[(match v [(p-1 e-1) ... (p-n e-n)])] hat, so kann 
man Pattern Matching verstehen als die Aufgabe, ein minimales @racket[i] zu finden, so dass
@racket[p-i] auf @racket[v] "matcht". Aber was bedeutet das genau?

Wir können Matching als eine Funktion definieren, die ein Pattern und einen Wert als Eingabe
erhält und entweder "no match" oder eine @italic{Substitution} zurückgibt.
Eine Substitution ist ein Mapping [x-1 := v-1, ..., x-n := v-n] von Namen auf Werte.
Wir können diese Funktion wie folgt definieren:

match(@racket[v],@racket[v]) = [] (die leere Substitution)

@margin-note{Es fehlen noch Spezialfälle für Listen, aber sie sind analog zur Behandlung von Strukturen.}
match(@racket[(struct id (p-1 ... p-n))], @racket[(make-id v-1 ... v-n)]) = 
  match(@racket[p-1],@racket[v-1]) + ... + match(@racket[p-n],@racket[v-n])

match(@racket[x],@racket[v]) = [@racket[x] := @racket[v]].

match(...,...) = "no match" in allen anderen Fällen.
Hierbei ist + ein Operator, der Substitutionen kombiniert. Das Ergebnis von s1+s2 ist
"no match", falls s1 oder s2 "no match sind" oder s1 und s2 beide ein Mapping für den gleichen Namen definieren  aber
diese auf unterschiedliche Werte abgebildet werden.

Falls in einem Ausdruck @racket[(match v [(p-1 e-1) ... (p-n e-n)])] gilt:

match(@racket[p-1],@racket[v]) = [@racket[x-1] := @racket[v-1],...,@racket[x-n] := @racket[v-n]]

so wird der Ausdruck reduziert zu @racket[e-1][@racket[x-1] := @racket[v-1],...,@racket[x-n] := @racket[v-n]].
Falls das Ergebnis hingegen "no match" ist, so wird der Ausdruck reduziert zu
@racket[(match v [(p-2 e-2) ... (p-n e-n)])].
