(ns foo
  (:require [clojure.java.jdbc :as sql])
  (:use [com.puppetlabs.puppetdb.scf.storage]
        [clj-time.core :only [ago secs now plus]]))

;; this will reports for 5000 nodes; approximately 7 days worth (assuming agent
;; runs 2x per hour).  it only generates reports, no events.

(let [db {:classname   "org.postgresql.Driver"
          :subprotocol "postgresql"
          :subname     "//localhost:5432/puppetdb"
          :user        "puppetdb"
          :password    "puppet"}]
  (let [certnames (map #(format "node%d" (+ % 1)) (range 5000))]
    (sql/with-connection db
      (doseq [certname certnames]
;       (println certname (now))
        (maybe-activate-node! certname (now))
        (dotimes [i 336]
          (let [timestamp   (now)
                start-time  (ago (secs (rand-int 10000000)))
                end-time    (plus start-time (secs 5))]

;            (println {:puppet-version         "2.7.19"
            (add-report! {:puppet-version         "2.7.19"
                          :certname               certname
                          :report-format          20
                          :configuration-version  "12345"
                          :start-time             start-time
                          :end-time               end-time
                          :resource-events        []}
                         timestamp)))))))
