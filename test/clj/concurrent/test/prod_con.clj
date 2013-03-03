(ns concurrent.test.prod-con
  (:use clojure.test
        concurrent.prod-con))

(deftest test-iterator-fn->lazy-seq
  (let [stack       (atom (range 5))
        counter     (atom 0)
        iterator-fn (fn []
                      (swap! counter inc)
                      (let [next-item (first @stack)]
                        (swap! stack next)
                        next-item))
        iterator-seq (iterator-fn->lazy-seq iterator-fn)]
    (testing "iterator-fn is not called until seq is accessed"
      (is (= 0 @counter)))
    (testing "iterator-fn is called exactly once if we take one item from the seq"
      (is (= 0 (first iterator-seq)))
      (is (= 1 @counter)))
    (testing "iterator-fn is not called again if we take the same item from the seq again"
      (is (= 0 (first iterator-seq)))
      (is (= 1 @counter)))
    (testing "iterator-fn is called one more time if we take the first two items from the seq"
      (is (= '(0 1) (take 2 iterator-seq)))
      (is (= 2 @counter)))
    (testing "iterator-fn is called once for each item in the seq, plus once for the final nil if we walk the whole seq"
      (doseq [i iterator-seq] i)
      (is (= 6 @counter)))))