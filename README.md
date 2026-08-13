# Common-Lisp-State-Space-Search-Implementations-
GENERAL-SEARCH, GOAL-P,BFS-ENQUEUER,DFS-ENQUEUER ,MANHATTAN-ENQUEUER,NUM-OUT-ENQUEUER implementations

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
