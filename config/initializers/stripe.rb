require 'stripe'

Stripe.api_key = ENV["STRIPE_API_KEY"]
Stripe.api_version = "2022-11-15"