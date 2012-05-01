module CloudSearchRails
  class MissingSearchDomain < Exception
    # constructor
    def initialize(klass)
      super("You must define a cloud_search_domain for #{klass}")
    end
  end
end