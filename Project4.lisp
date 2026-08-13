

;;; STATE SPACE SEARCH

;;; WHAT YOU MUST DO
;;;
;;; STAGE 1
;;;
;;; Your job is to implement the following functions:
;;;
;;; GENERAL-SEARCH      (general search function)
;;; GOAL-P              (goal testing predicate)
;;; BFS-ENQUEUER        (enqueues in breadth-first order)
;;; DFS-ENQUEUER        (enqueues in depth-first order)
;;; MANHATTAN-ENQUEUER  (enqueues by manhattan distance)
;;; NUM-OUT-ENQUEUER    (enqueues by number of tiles out of place)
;;;
;;; You may write auxillary functions if necessary.  Make sure you
;;; implement true A* search under the assumption of monotonicity
;;; (don't maintain the pointers).
;;;
;;; You then will run your four enqueueing functions on the five 
;;; examples at the end of this file and report, in a neatly-organized
;;; table as comments in the code, the number of iterations it took to
;;; solve each example. If it's taking more than 20000 iterations, you
;;; may simply state that the example FAILED for the function.  In every
;;; case except for depth-first search possibly, you should find the
;;; solution with the smallest number of moves, if you find a solution
;;; at all.  The minimal number of moves is already indicated next to the
;;; example.
;;;
;;; Additionally, you should also provide the actual solutions that
;;; MANHATTAN-ENQUEUER discovered for the first four examples, and
;;; state why you believe the fifth example is (or isn't) difficult
;;; for MANHATTAN-ENQUEUER.
;;;
;;; Once you have implemented these functions, it's easy to run them.
;;; Here's the manhattan enqueuer being run on example #6, with the
;;; result being printed out in a pleasing fashion.
;;;
;;; (setf s (make-initial-state '(1 8 9 3 2 4 6 5 7)))
;;; (print-solution (general-search s #'goal-p #'manhattan-enqueuer))
;;;
;;;
;;; STAGE 2
;;;
;;; You must now change the puzzle from an
;;; 8 puzzle to a 15 puzzle.  This will require modifying the state
;;; structure, and be on the lookout for the number NINE in the code,
;;; you'll need to modify it to something else.  In most cases 9 means
;;; something special -- what is it?  Then repeat the experiment and
;;; report a table for the number of iterations to solve each example.
;;; You are allowed incresae the maximum number of iterations from 20000
;;; to something else.
;;;
;;;
;;; WHAT TO SEND TO THE TA
;;;
;;; Mail the following to the TA, as a single lisp file:
;;;
;;; 1. Your completed functions and any auxillary functions and data
;;;    you wrote to support them for the 8-puzzle
;;; In comments at the end of the file: 
;;;    2. The number of iterations required for each of the 4 functions
;;;       on each of the 5 examples for the 8-puzzle
;;;    3. The actual printed out solutions for MANHATTAN-ENQUEUER on the
;;;       first four examples for the 8-puzzle
;;;    4. A 500 word report detailing how you implemented your functions,
;;;       why you thought various techniques did better than others,
;;;       and your explanation for why the fifth example is easy or hard
;;;       for MANHATTAN-ENQUEUER. 
;;;    5. Include a separate lisp file called "15.lisp" which includes
;;;       items #1 (with modified code), #2, and #3 above again.


;;; WHAT'S PROVIDED
;;;
;;; Accompanying this file are two other files: "utilities.lisp" and
;;; "queue.lisp".  utilities.lisp must be loaded first, then queue.lisp.
;;;  queue.lisp is what you need to take a look at: it's an implementation
;;; of three kinds of queues: LIFO stacks, FIFO queues, and priority queues.
;;; You will find it useful.
;;;
;;; In the homework file (this one), are many functions and macros :-) which 
;;; operate on 8-puzzles.  They should be pretty self-explanatory.  One
;;; function you won't use in your code, but might find useful to test with,
;;; is CREATE-RANDOM-STATE, which makes lots of random moves on an 8-puzzle
;;; to randomize it.  Most of the macros are there just for function-inlining,
;;; except for the two provided FOREACH-... macros.  See if you can understand
;;; them.


;;; EXTRA CREDIT
;;;
;;; Worried about your course score so far?  Here's a chance for some extra 
;;; credit.
;;;
;;; Extra credit counts after the class has been ranked and assigned grades,
;;; so you getting extra credit doesn't affect the grades of other students
;;; relative to yourself.  Do at least one of:
;;;
;;; 1. Change to a different puzzle.  2x2x2 rubik's cube, peg solitaire, a 
;;;    "Dad's Puzzle" (piano-mover's puzzle).  You need to provide a somewhat
;;;    intelligent new heuristic.
;;;
;;; 2. Implement IDS and report on it.
;;;
;;; 3. Implement a combination of A* and IDS, called IDA*.  See
;;;    https://en.wikipedia.org/wiki/Iterative_deepening_A*
;;;
;;; 4. Implement simple best-first search (that is, f = h).
;;;    Does it always find minimum solutions?
;;;
;;; 5. There is an inefficiency in my representation: you have to call
;;;    (depth _state_) rather than the state already knowing its depth.
;;;    That multiplies the complexity by an additional O(lg n).  You might
;;;    try storing the depth in the state somehow and see how much faster
;;;    that gets you.

;;; To submit extra credit, put your additional changes into a separate 
;;; subdirectory called "extracredit".  Include a README in that directory
;;; indicating what you did.  Be specific.  Help us understand.


;;; THE NUM-OUT AND MANHATTAN HEURISTICS
;;;
;;; The NUM-OUT heuristic is simply the total number of tiles out of place 
;;; (not including the blank space).
;;;
;;; The MANHATTAN heuristic is the sum, over each tile (not including the
;;; blank), of the manhattan distance of that tile from where it's supposed
;;; to be.  Manhattan distance between two points <x,y> and <x2,y2> is equal
;;; to |x-x2| + |y-y2|, that is, it's the difference along the x dimension
;;; plus the difference along the y dimension.
;;;
;;; Example:
;;;
;;; In the following puzzle:
;;;
;;; 1 8 3
;;; 9 6 5     (9 is the blank -- ignore it)
;;; 7 4 2
;;;
;;; NUM-OUT = (#8 out of place) + (#6 out of place) + (#5 out of place) + 
;;;           (#4 out of place) + (#2 out of place) = 5
;;;
;;; MANHATTAN:   TILE     X OUT    Y OUT
;;;              #1       0        0
;;;              #2       1        2
;;;              #3       0        0
;;;              #4       1        1
;;;              #5       1        0
;;;              #6       1        0
;;;              #7       0        0
;;;              #8       0        2
;;;      Total            4   +    5     =  9
;;;
;;; Both heuristics are both admissable and, I believe, monotonic.  Which
;;; one is better?



;;; THE 8-PUZZLE REPRESENTATION
;;; 
;;; 8-puzzles are simple-vectors of integers with 10 slots.
;;; Slots 0...8 are the positions in the puzzle in row-major
;;; order, filled
;;; with numbers representing the tile that's in that slot
;;; (9 is the empty space).  slot 9 additionally says where
;;; the empty space is located.  Of course slot 9 is unnecessary,
;;; but it makes the puzzle much more efficient than wandering through
;;; the array each time looking for a 9.  So for example,
;;; the following puzzle:
;;;
;;; 2 7 4
;;; 9 8 3
;;; 1 5 6
;;;
;;; ...is stored in a simple-vector with the following values:
;;;
;;; #(2 7 4 9 8 3 1 5 6 3)
;;;
;;; ...the last item (3) says that the empty space, represented
;;; as a 9, is located in slot 3 of the array.
;;;
;;; One way that you could do state-based search is to treat a PUZZLE
;;; as a STATE.  But we're not going to do that.  We want to keep a
;;; history around so we know *how* we got to that puzzle situation.
;;; So a STATE will be defined as CONS cell whose CAR points to the
;;; puzzle, and whose CDR points to the previous state.  Our initial
;;; state's CDR points to nil. The nice thing about doing it this way
;;; is that when you get to the goal state, it appears to be just
;;; a list of states all the way back to the initial state.
;;;
;;; As such the functions below are very carefully named as operating
;;; on STATES or on PUZZLES.  Don't mix them up!


;;; THE ALGORITHM

;;; The search algorithm we'll use is a slight modification of the one
;;; given in class.  If you go through it you'll realize it's basically
;;; the same thing, with the following changes:
;;;
;;; 1. No maximum depth.  We keep around a history list, so the depth
;;;    isn't, erm, technically necessary.  :-)
;;; 2. Maximum number of iterations before we bag it and quit
;;; 3. Our enqueueing function evaluates the states' F(s) values and
;;;    enqueues them, all in one swoop
;;; 4. Keep in mind that in a heuristic version of the search,
;;;    the enqueuing function enqueues by the g(s) + h(s),
;;;    NOT just by the h(s).

;;; Here we go:


;;; GeneralSearch(InitialState, GoalTest, EnqueueingFunction, MaxIterations)
;;;   make new empty queue
;;;   make new empty history
;;;   iterations <- 0
;;;   state <- InitialState
;;;
;;;   EnqueuingFunction(queue,state)
;;;   add the state's puzzle to history
;;;
;;;   loop:
;;;     iterations++
;;;     if (iterations > MaxIterations or queue is empty) return 'FAILED
;;;     state <- dequeue(queue)
;;;     if GoalTest(state)
;;;        print out number of iterations
;;;        return state
;;;     else for each child of the state
;;;        process child (as in Djikstra's)
;;;        if the child's puzzle is not in the history
;;;           EnqueuingFunction(queue,child [state])
;;;           add child [puzzle] to history



(defun make-initial-state (initial-puzzle-situation)
  "Makes an initial state with a given puzzle situation.
    The puzzle situation is simply a list of 9 numbers.  So to
    create an initial state with the puzzle
    2 7 4
    9 8 3
    1 5 6
    ...you would call (make-initial-state '(2 7 4 9 8 3 1 5 6))"
  (cons (concatenate 'simple-vector initial-puzzle-situation 
                     (list (position 9 initial-puzzle-situation))) nil))

(defmacro depth (state)
  "Returns the number of moves from the initial state 
    required to get to this STATE"
  `(1- (length ,state)))

(defmacro puzzle-from-state (state)
  "Returns the puzzle (an array of 10 integers) from STATE"
  `(first ,state))

(defmacro previous-state (state)
  "Returns the previous state that got us to this STATE"
  `(rest ,state))

(defmacro empty-slot (puzzle)
  "Returns the position of the empty slot in PUZZLE"
  `(elt ,puzzle 9))

(defun create-random-state (num-moves)
  "Generates a random state by starting with the
    canonical correct puzzle and making NUM-MOVES random moves.
    Since these are random moves, it could well undo previous
    moves, so the 'randomness' of the puzzle is <= num-moves"
  (let ((puzzle #(1 2 3 4 5 6 7 8 9 8)))
    (dotimes (x num-moves)
      (let ((moves (elt *valid-moves* (empty-slot puzzle))))
        (setf puzzle (make-move (elt moves (random (length moves))) puzzle))))
    (build-state puzzle nil)))

(defun swap (pos1 pos2 puzzle)
  "Returns a new puzzle with POS1 and POS2 swapped in original PUZZLE.  If
    POS1 or POS2 is empty, slot 9 is updated appropriately."
  (let ((tpos (elt puzzle pos1)) (puz (copy-seq puzzle)))
    (setf (elt puz pos1) (elt puz pos2))  ;; move pos2 into pos1's spot
    (setf (elt puz pos2) tpos)  ;; move pos1 into pos2's spot
    (if (= (elt puz pos1) 9) (setf (empty-slot puz) pos1)  ;; update if pos1 is 9
        (if (= (elt puz pos2) 9) (setf (empty-slot puz) pos2)))  ;; update if pos2 is 9
    puz))

(defparameter *valid-moves* 
  #((1 3) (0 2 4) (1 5) (0 4 6) (1 3 5 7) (2 4 8) (3 7) (4 6 8) (5 7))
  "A vector, for each empty slot position, of all the valid moves that can be made.
    The moves are arranged in lists.")

(defmacro foreach-valid-move ((move puzzle) &rest body)
  "Iterates over each valid move in PUZZLE, setting
    MOVE to that move, then executing BODY.  Implicitly
    declares MOVE in a let, so you don't have to."
  `(dolist (,move (elt *valid-moves* (empty-slot ,puzzle)))
     ,@body))

(defun make-move (move puzzle)
  "Returns a new puzzle from original PUZZLE with a given MOVE made on it.
    If the move is illegal, nil is returned.  Note that this is a PUZZLE,
    NOT A STATE.  You'll need to build a state from it if you want to."
  (let ((moves (elt *valid-moves* (empty-slot puzzle))))
    (when (find move moves) (swap move (empty-slot puzzle) puzzle))))

(defmacro build-state (puzzle previous-state)
  "Builds a state from a new puzzle situation and a previous state"
  `(cons ,puzzle ,previous-state))

(defmacro foreach-position ((pos puzzle) &rest body)
  "Iterates over each position in PUZZLE, setting POS to the
    tile number at that position, then executing BODY. Implicitly
    declares POS in a let, so you don't have to."
  (let ((x (gensym)))
    `(let (,pos) (dotimes (,x 9) (setf ,pos (elt ,puzzle ,x))
                   ,@body))))

(defun print-puzzle (puzzle)
  "Prints a puzzle in a pleasing fashion.  Returns the puzzle."
  (let (lis)
    (foreach-position (pos puzzle)
                      (if (= pos 9) (push #\space lis) (push pos lis)))
    (apply #'format t "~%~A~A~A~%~A~A~A~%~A~A~A" (reverse lis)))
  puzzle)

(defun print-solution (goal-state)
  "Starting with the initial state and ending up with GOAL-STATE,
    prints a series of puzzle positions showing how to get 
    from one state to the other.  If goal-state is 'FAILED then
    simply prints out a failure message"
  ;; first let's define a recursive printer function
  (labels ((print-solution-h (state)
             (print-puzzle (puzzle-from-state state)) (terpri)
             (when (previous-state state) (print-solution-h (previous-state state)))))
    ;; now let's reverse our state list and call it on that
    (if (equalp goal-state 'failed) 
        (format t "~%Failed to find a solution")
        (progn
          (format t "~%Solution requires ~A moves:" (1- (length goal-state)))
          (print-solution-h (reverse goal-state))))))



(defun general-search (initial-state goal-test enqueueing-function &optional (maximum-iterations nil))
  "Starting at INITIAL-STATE, searches for a state which passes the GOAL-TEST
    function.  Uses a priority queue and a history list of previously-visited puzzles.
    Enqueueing in the queue is done by the provided ENQUEUEING-FUNCTION.  Prints 
    out the number of iterations required to discover the goal state.  Returns the 
    discovered goal state, else returns the symbol 'FAILED if the entire search 
    space was searched and no goal state was found, or if MAXIMUM-ITERATIONS is 
    exceeded.  If maximum-iterations is set to nil, then there is no maximum number
    of iterations."

  (let ((open (make-empty-queue))
        (history nil) ; list of visited puzzles
        (iterations 0))
    ;; Put initial state into queue using strategy of choice
    (funcall enqueueing-function initial-state open)

    (loop
      ;; If the queue is empty, search space has been used 
      (when (empty-queue? open)
        (format t "Search failed after ~D iterations (queue exhausted).~%" iterations)
        (return 'FAILED))

      ;; Respect max-iterations limit if provided
      (when (and maximum-iterations
                 (>= iterations maximum-iterations))
        (format t "Search failed after ~D iterations (limit ~D exceeded).~%" iterations maximum-iterations)
        (return 'FAILED))

      ;; Expand one more state
      (incf iterations)

      ;; Take next state in front of queue
      (let* ((state (queue-front open))
             (puzzle (puzzle-from-state state)))
        (remove-front open)

        ;; If puzzle seen, skip
        (when (not (member puzzle history :test #'equalp))
          ;; Mark visited
          (push puzzle history)

          ;; Check for goal
          (when (funcall goal-test state)
            (format t "Goal found in ~D iterations.~%" iterations)
            (return state))

          ;; Expand and generate all valid successor states
          (foreach-valid-move (move puzzle)
                              (let ((new-puzzle (make-move move puzzle)))
                                (when new-puzzle
                                  (let ((child (build-state new-puzzle state)))
                                    (funcall enqueueing-function child open))))))))))


(defun goal-p (state)
  "Returns T if state is a goal state, else NIL.  Our goal test."
  (equalp (puzzle-from-state state)
          #(1 2 3 4 5 6 7 8 9 8)))

(defun dfs-enqueuer (state queue)
  "Enqueues in depth-first order"
  ;; LIFO stack always removing from front in GENERAL-SEARCH, insert newly generated state at front so they are expanded next.
  (enqueue-at-front queue state)
  queue)

(defun bfs-enqueuer (state queue)
  "Enqueues in breadth-first order"
  ;; Treat the queue as FIFO, add new states at end so that shallow states are expanded before deeper ones.
  (enqueue-at-end queue state)
  queue)                                         

(defun manhattan-heuristic (puzzle)
  "Sum of Manhattan distances of all tiles (excluding the blank 9)
from their goal positions."
  (let ((sum 0))
    (dotimes (i 9 sum)
      (let ((tile (elt puzzle i)))
        (when (/= tile 9)
          (let* ((goal-index (1- tile))    
                 (cur-x   (mod i 3))
                 (cur-y   (floor i 3))
                 (goal-x  (mod goal-index 3))
                 (goal-y  (floor goal-index 3)))
            (incf sum (+ (abs (- cur-x goal-x))
                         (abs (- cur-y goal-y))))))))))

(defun manhattan-f-cost (state)
  "A* f-cost using Manhattan heuristic: f(n) = g(n) + h(n)."
  (+ (depth state)
     (manhattan-heuristic (puzzle-from-state state))))

(defun manhattan-enqueuer (state queue)
  "Enqueues by manhattan distance"
  ;; Priority key: f(n) = depth(state) + h_manhattan(puzzle)
  (enqueue-by-priority queue #'manhattan-f-cost state)
  queue)

(defun num-out-heuristic (puzzle)
  "Number of tiles out of place (excluding the blank 9)."
  (let ((count 0))
    (dotimes (i 9 count)
      (let ((tile (elt puzzle i)))
        (when (and (/= tile 9)
                   (/= tile (1+ i))) 
          (incf count))))))

(defun numout-f-cost (state)
  "A* f-cost using NUM-OUT heuristic: f(n) = g(n) + h(n)."
  (+ (depth state)
     (num-out-heuristic (puzzle-from-state state))))

(defun num-out-enqueuer (state queue)
  "Enqueues by number of tiles out of place"
  ;; Priority key: f(n) = depth(state) + h_num-out(puzzle)
  (enqueue-by-priority queue #'numout-f-cost state)
  queue)

#|
;;; The five test examples.

;;; Solves in 4 moves:
(setf s (make-initial-state '(
9 2 3
1 4 6
7 5 8)))

;;; Solves in 8 moves:
(setf s (make-initial-state '(
2 4 3
1 5 6
9 7 8)))

;;; Solves in 16 moves:
(setf s (make-initial-state '(
2 3 9
5 4 8
1 6 7)))

;;; Solves in 24 moves:
(setf s (make-initial-state '(
1 8 9
3 2 4
6 5 7)))

;;; easy or hard to solve?  Why?
(setf s (make-initial-state '(
9 2 3
4 5 6
7 8 1)))

--#2 Test Outputs#--

-BFS
test 1 solved in 4 moves 67 iterations.
test 2 solved in 8 moves 3187 iterations. 
test 3 solved in 16 moves 16519 iterations. 
test 4 could not be solved in 20k iterations.
test 5 cannot be solved.   
        
-DFS
test 1 solved in 49 iterations.
test 2 solved in 3196 iterations.
test 3 solved in 18400 iterations. 
test 4 failed in 20k iterations. 
test 5 cannot be solved. 

-A* with tiles-out
test 1 passed in 5 iterations.
test 2 passed in 18 iterations. 
test 3 passed in 568 iterations. 
test 4 failed in 20k iterations. 
test 5 failed. (unsolvable)      
              
-A* with Manhattan
test 1 passed in 5 iterations.
Output:
(let ((res (general-search *s1* #'goal-p #'manhattan-enqueuer 20000)))
(if (eq res 'FAILED)
(format t "A* Manhattan Example 1: FAILED~%")
(format t "A* Manhattan Example 1: solved in ~D moves.~%"
(depth res))))
Goal found in 5 iterations.
A* Manhattan Example 1: solved in 4 moves.

test 2 passed in 14 iterations.
Output:
(let ((res (general-search *s2* #'goal-p #'manhattan-enqueuer 20000)))
(if (eq res 'FAILED)
(format t "A* Manhattan Example 2: FAILED~%")
(format t "A* Manhattan Example 2: solved in ~D moves.~%"
(depth res))))
Goal found in 14 iterations.
A* Manhattan Example 2: solved in 8 moves.

test 3 passed in 83 iterations.
Output:
(let ((res (general-search *s3* #'goal-p #'manhattan-enqueuer 20000)))
(if (eq res 'FAILED)
(format t "A* Manhattan Example 3: FAILED~%")
(format t "A* Manhattan Example 3: solved in ~D moves.~%"
(depth res))))
Goal found in 82 iterations.
A* Manhattan Example 3: solved in 16 moves.

test 4 passed in 700 iterations.
Output:
(let ((res (general-search *s4* #'goal-p #'manhattan-enqueuer 20000)))
(if (eq res 'FAILED)
(format t "A* Manhattan Example 4: FAILED~%")
(format t "A* Manhattan Example 4: solved in ~D moves.~%"
(depth res))))
Goal found in 700 iterations.
A* Manhattan Example 4: solved in 24 moves.

test 5 is unsolvable. 

Report:

The puzzle represented is a simple-vector of 10 integers, 0-8 of which are tiles and 9 is the blank index. A state chain is (puzzle. previous-states), so depth is just the length of the chain minus 1. General-search is generic and doesn't know about the puzzles or heuristics, it just
removes a state from the queue, tests goal-p, then it generates successors with successors-of. The implementation makes an open priority queue, and on each loop it checks if the queue is empty, respects max iterations, and pop the best state with queue-front. History prevents revisits. Essentially, the behaviour is controlled by the enqueue function (BFS, DFS, A*). This allows the algorithm to remain flexible and the same search loop can perform uninformed search, heuristic search, or custom search orders by changing the enqueueing function. This allows us to plug in new heuristics without changing the initial search function.

BFS does not use a heuristic and can often be unwieldy. Even though the 8 puzzle is small the depth can grow to storing thousands of states in the queue. It explodes quickly in memory and time as depth increases. Later test examples would either hit the iteration limit or take a very long time. DFS can go very deep before it does backtracking. It is often not guaranteed to find the shortest path and may miss shallowest solution for a long time.
It can be faster or slower than BFS depending on luck or branch structure. It is sensitive to move ordering and can get stuck exploring "bad" parts of the space. 

A* with Tiles-out (or NUM-OUT) prioritizes states with few tiles misplaced. It is a "weak" heuristic and often explores many states which are kind of random.  
The implementation uses the index directly to check the goal position (i.e. tile t should be at t-1) so it does not search each tile's goal position and does not require any data structures. 
Harder examples still prove difficult. A* with Manhattan is a stronger heuristic because it differentiates between states with same tiles-out count by how far tiles are from their correct positions. The implementation uses simple arithmetic on the indices instead of searching for tiles. 
It usually dominates tiles-out for all states in performance. 

The reason that example 5 would be hard for the A* Manhattan is because it is a unsolvable configuration of the 8 puzzle. Manhattan and Tiles-out do not know about parity and primarily estimate distance to the goal assuming it is reachable. 
In general these will dominate the entire search space as the goal is not reachable in this configuration. Another reason for this is at runtime A* Manhattan pulls the lowest f (n) states off the heap, generates successors via for each-valid-move and make-move. Therefore it is fooled in this case because it is only estimating distance. Incorporating parity or inversion-count pre-check would allow the program to detect this but neither heuristic uses this logic. 
|#


