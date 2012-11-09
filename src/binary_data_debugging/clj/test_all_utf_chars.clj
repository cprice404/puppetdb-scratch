(defn numeric-seq-to-utf8-bytes
  [nums]
  (let [nums (byte-array (map #(.byteValue (Integer. %)) nums))]
    (.getBytes (String. nums "UTF-8"))))

(defn byte-seq-to-utf8-bytes
  [bytes]
  (.getBytes (String. (byte-array bytes) "UTF-8")))

(defn filter-leading-zeroes
  [bytes]
;; this isn't correct -- it filters all zeroes
  (if (= 0 (first bytes))
    (filter-leading-zeroes (rest bytes))
    bytes))

(defn readable-bytes
  [bytes]
  (clojure.string/join " " (map #(format "0x%02x" %) bytes)))

(defn long-to-bytes
  [long]
  (.array (.putLong (java.nio.ByteBuffer/allocate 8) long)))

(doseq [i (range 1 0xffffffff)]
  (let [bytes (filter-leading-zeroes (long-to-bytes i))
        utf8-bytes (byte-seq-to-utf8-bytes bytes)]
    (if (not (= (set bytes) (set utf8-bytes)))
      (println (format "[%s] : [%s]"
                (readable-bytes bytes)
                (readable-bytes utf8-bytes))))))



