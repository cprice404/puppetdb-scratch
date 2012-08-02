(ns foo
  (:use [criterium.core])
  (:require [clojure.java.jdbc :as sql]
            [clojure.java.jdbc.internal :as sql-internal]))

(defn my-bench [desc f]
  (println (format "\n
Beginning benchmark for '%s'
-----------------------------------------------------" desc))
  (time (with-progress-reporting (bench (f)
                                   :verbose
;                                   :target-execution-time (* 10 60 1000 1000)
                                   )))
  (println "\n\n"))

(defn build-statement [sql]
  (sql-internal/prepare-statement* (:connection sql-internal/*db*) sql))

(defn execute-statement [stmt]
  (with-open [stmt stmt]
    (.executeQuery stmt)
    nil))

(defn noop-select []
  (execute-statement (build-statement "SELECT 1 as foo")))

(defn select-with-limit []
  (execute-statement (build-statement "select * from catalog_resources where type = 'File' LIMIT 1000")))

(defn subselect-with-limit []
  (execute-statement (build-statement "select a.* from (select * from catalog_resources where type = 'File') a LIMIT 1000")))

(defn select-with-fetch-size []
  (execute-statement
    (let [stmt (build-statement "select * from catalog_resources where type = 'File'")]
      (.setFetchSize stmt 1000)
      stmt)))

(defn dumb-select []
  (execute-statement (build-statement "select * from catalog_resources where type = 'File'")))



(sql/with-connection
  { :classname "org.postgresql.Driver"
    :subprotocol "postgresql"
    :subname "//localhost:5432/puppetdb_large"
    :user "puppet"
    :password "puppet"
    }
;
;  (let [stmt (build-statement "SELECT 1 as foo")]
;    (println (str "Statement default fetch size is " (.getFetchSize stmt))))

  (my-bench "no-op select" noop-select)
  (my-bench "select with limit" select-with-limit)
  (my-bench "subselect with limit" subselect-with-limit)
  (my-bench "dumb select" dumb-select)
  (my-bench "select with fetch size" select-with-fetch-size)

  )

(println "Done")



;  (with-open [stmt (build-statement "SELECT 1 as foo")]
;    (.executeQuery stmt)
;    nil))
;    (with-open [result-set  (.executeQuery stmt)]
;      (doseq [result (sql-internal/resultset-seq* result-set)]
;        ;            (println (str result (type result))))))
;        (str result (type result))
;        0))))
