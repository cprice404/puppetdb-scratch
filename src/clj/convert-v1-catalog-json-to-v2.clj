(ns foo
  (:require [fs.core :as fs]
            [cheshire.core :as json])
  (:use     [clojure.core.incubator :only [dissoc-in]]))

(let [path "/home/cprice/work/puppet/puppetdb/scratch/import-export/import_test//puppetdb_bak/catalogs"]
  (fs/mkdir (fs/file path "orig"))
  (doseq [catalog-file (fs/glob (fs/file path "*.json"))]
    (let [catalog-filename    (fs/base-name catalog-file)
          orig-catalog-file   (fs/file path "orig" catalog-filename)
          catalog             (json/parse-string (slurp catalog-file))]
      (fs/rename catalog-file orig-catalog-file)
      (println (format "processing catalog from '%s' to '%s'" orig-catalog-file catalog-file))
      (spit catalog-file
        (-> catalog
          (dissoc-in ["data" "tags"])
          (dissoc-in ["data" "classes"])
          (json/generate-string {:pretty true}))))))
