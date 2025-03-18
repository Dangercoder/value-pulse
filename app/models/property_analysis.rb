class PropertyAnalysis < ApplicationRecord
     validates :address, length: { minimum: 5 }

     enum :state, {
        pending: 'pending',
        processing: 'processing',
        completed: 'completed',
        error: 'error'
      }

end
