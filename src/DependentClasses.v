Require Import String List.

From mathcomp Require Import ssreflect ssrfun ssrbool ssrnat eqtype seq.

Require Import GenLow GenHigh Tactics Sets Classes.
Import GenLow GenHigh.
Import ListNotations.
Import QcDefaultNotation.

Open Scope qc_scope.
Open Scope string.

Set Bullet Behavior "Strict Subproofs".

(** * Correctness of dependent generators *)

(** Apply a function n times *)
Fixpoint app {A} (f : A -> A) (n : nat) : A ->  A :=
  fun x =>
    match n with
      | 0%nat => x
      | S n' => f (app f n' x)
    end.

Infix "^" := app (at level 30, right associativity) : fun_scope.



Class SizedProofEqs {A : Type} (P : A -> Prop) :=
  {
    zero : set A;
    succ : set A -> set A;
    spec : \bigcup_(n : nat) ((succ ^ n) zero) <--> P
  }.

(* Looks like Scott induction, although we have not proved that
   succ is continuous *)
Lemma fixed_point_ind {A} (Q P : A -> Prop) `{SizedProofEqs A P}:
  zero \subset Q ->
  (forall (s : set A), s \subset Q -> succ s \subset Q) ->
  P \subset Q.
Proof.
  intros Hz IH. rewrite <- spec. intros x [n [_ HP]].
  revert x HP. 
  induction n.
  - eauto.
  - intros x. eapply IH. eauto.
Qed.

Definition lift {A} (S : set A) : set (option A) :=
  Some @: S :|: [set None].

Class SizedSuchThatCorrect {A : Type} (P : A -> Prop) `{SizedProofEqs A P} (g : nat -> G (option A)) :=
  {
    sizedSTCorrect :
      forall s,
        Some @: ((succ ^ s) zero) \subset semGen (g s) /\
        semGen (g s) \subset lift ((succ ^ s) zero)
  }.

Class SuchThatCorrect {A : Type} (P : A -> Prop) (g : G (option A)) :=
  {
    STCorrect :
      Some @: [set x : A | P x ] \subset semGen g /\
      semGen g \subset lift [set x : A | P x ]
  }.

(** * Dependent sized generators *)

Class GenSizedSuchThat (A : Type) (P : A -> Prop) :=
  {
    arbitrarySizeST : nat -> G (option A);
  }.

(** * Monotonicity of denendent sized generators *)

Class GenSizedSuchThatMonotonic (A : Type)
      `{GenSizedSuchThat A} `{forall s, SizeMonotonic (arbitrarySizeST s)}.

Class GenSizedSuchThatSizeMonotonic (A : Type)
      `{GenSizedSuchThat A} `{SizedMonotonic _ arbitrarySizeST}.

(** * Correctness of denendent sized generators *)
  
Class GenSizedSuchThatCorrect (A : Type) (P : A -> Prop)
      `{GenSizedSuchThat A P}
      `{SizedSuchThatCorrect A P arbitrarySizeST}.

(** * Dependent generators *)

Class GenSuchThat (A : Type) (P : A -> Prop) :=
  {
    arbitraryST : G (option A);
  }.

(** * Monotonicity of denendent generators *)

Class GenSuchThatMonotonic (A : Type) (P : A -> Prop) `{GenSuchThat A P}
      `{@SizeMonotonic _ arbitraryST}.

(** * Correctness of dependent generators *)  

Class GenSuchThatCorrect {A : Type} (P : A -> Prop) 
      `{GenSuchThat A P}
      `{SuchThatCorrect A P arbitraryST}.

Class GenSuchThatMonotonicCorrect (A : Type) (P : A -> Prop)
      `{GenSuchThat A P}
      `{@SizeMonotonic _ arbitraryST}
      `{SuchThatCorrect A P arbitraryST}.

(** * Coercions from sized to unsized generators *)
  
Instance GenSuchThatOfSized (A : Type) (P : A -> Prop)
         `{GenSizedSuchThat A P} : GenSuchThat A P :=
  {
    arbitraryST := sized arbitrarySizeST;
  }.

Generalizable Variables PSized PMon PSMon PCorr.

Lemma bigcup_setU_r:
  forall (U T : Type) (s : set U) (f g : U -> set T),
    \bigcup_(i in s) (f i :|: g i) <-->
    \bigcup_(i in s) f i :|: \bigcup_(i in s) g i.
Proof.
  firstorder.
Qed.

Lemma lift_bigcup_comm :
  forall (U T : Type) (s : set U) (f : U -> set T),
    inhabited U ->
    lift (\bigcup_(i in [set : U]) (f i)) <-->
    \bigcup_(i in [set : U]) (lift (f i)).
Proof.
  intros U T s f Hin. unfold lift.
  rewrite !bigcup_setU_r -!imset_bigcup.
  rewrite bigcup_const; eauto.
  reflexivity.
Qed.
    
Instance GenSuchThatMonotonicOfSized (A : Type) (P : A -> Prop)
         {H : GenSizedSuchThat A P}
         `{@GenSizedSuchThatMonotonic A P H PMon}
         `{@GenSizedSuchThatSizeMonotonic A P H PSMon}
: GenSuchThatMonotonic A P.

Instance ArbitraryCorrectFromSized (A : Type) (P : A -> Prop)
         {H : GenSizedSuchThat A P}
         `{@GenSizedSuchThatMonotonic A P H PMon}
         `{@GenSizedSuchThatSizeMonotonic A P H PSMon}
         `{@GenSizedSuchThatCorrect A P H PSized PCorr}
: SuchThatCorrect P arbitraryST.
Proof.
  constructor. unfold arbitraryST, GenSuchThatOfSized.
  rewrite semSized_alt.
  split.
  - eapply subset_trans;
    [ | eapply incl_bigcupr; now eapply sizedSTCorrect ].
    rewrite <-imset_bigcup, spec. eapply subset_refl.
  - eapply subset_trans. eapply incl_bigcupr.
    intros x. now eapply sizedSTCorrect.
    unfold lift.
    rewrite bigcup_setU_r.
    rewrite <-imset_bigcup, spec.
    rewrite bigcup_const. eapply subset_refl.
    constructor. exact 0.
  - destruct PSMon. eauto.
Qed.
  
(* TODO: Move to another file *)
(*
(** Leo's example from DependentTest.v *)

Print Foo.
Print goodFooNarrow.

DeriveSized Foo as "SizedFoo".

(*
Inductive Foo : Set :=
    Foo1 : Foo | Foo2 : Foo -> Foo | Foo3 : nat -> Foo -> Foo

Inductive goodFooNarrow : nat -> Foo -> Prop :=
    GoodNarrowBase : forall n : nat, goodFooNarrow n Foo1
  | GoodNarrow : forall (n : nat) (foo : Foo),
                 goodFooNarrow 0 foo ->
                 goodFooNarrow 1 foo -> goodFooNarrow n foo
 *)

(* Q : Can we but the size last so we don't have to eta expand?? *)
Print genGoodNarrow. 

(** For dependent gens we show generate this instance *)
Instance genGoodNarrow (n : nat) : ArbitrarySizedSuchThat Foo (goodFooNarrow n) :=
  {
    arbitrarySizeST := genGoodNarrow' n;
    shrinkSizeST x := []
  }.

(* For proofs we should generate this instances *)

Instance genGoodNarrowMon (n : nat) (s : nat) :
  SizeMonotonic (@arbitrarySizeST Foo (goodFooNarrow n) _ s).
Abort.

Instance genGoodNarrowSMon (n : nat) :
  @ArbitrarySTSizedSizeMotonic Foo (@goodFooNarrow n) _.
Abort.

Instance genGoodNarrowCorr (n : nat) :
  GenSizeSuchThatCorrect (goodFooNarrow n) (@arbitrarySizeST Foo (goodFooNarrow n) _).
Abort.
*)

(** We can now abstract away from sizes and get the generator and the proofs for free *)