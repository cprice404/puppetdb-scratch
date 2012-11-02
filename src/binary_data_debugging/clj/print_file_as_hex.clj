(def slurped (slurp "./bad_binary_data.out"))

(println
  (clojure.string/join " "
    (map #(format "0x%02x" %) (.getBytes slurped "UTF-8"))))
