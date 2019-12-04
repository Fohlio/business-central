module BusinessCentral
  module Object
    class CashFlowStatement < Base
      OBJECT = 'cashFlowStatement'.freeze

      OBJECT_METHODS = [
        :get
      ].freeze

      def initialize(client, company_id:)
        super(client, company_id: company_id)
        @parent_path = [
          {
            path: 'companies',
            id: company_id
          }
        ]
      end
    end
  end
end