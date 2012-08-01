(ns foo
  (:require [com.puppetlabs.puppetdb.core :as cli-core]))


(cli-core/-main "services" "-c" "/home/cprice/work/puppetdb/conf/config.ini")
