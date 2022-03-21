class Ticket < ApplicationRecord
    enum status: %w[booked paid blocked] 
end
