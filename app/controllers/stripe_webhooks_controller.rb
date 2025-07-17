class StripeWebhooksController < ApplicationController
    skip_forgery_protection
    allow_unauthenticated_access only: [:webhook]
  
    # Subscription Create
    def create_checkout_session
      price_id = params[:price_id]
      return render json: { error: 'Missing price_id' }, status: :bad_request unless price_id
  
      user = Current.user
      return render json: { error: 'User not signed in' }, status: :unauthorized unless user
  
      customer = find_or_create_stripe_customer(user)
  
      session = Stripe::Checkout::Session.create({
        customer: customer.id,
        success_url: root_url + "?success=true",
        cancel_url: root_url + "?canceled=true",
        payment_method_types: ['card'],
        mode: 'subscription',
        billing_address_collection: 'required',
        customer_update: {
          name: 'auto',
          address: 'auto'
        },
        line_items: [{
          price: price_id,
          quantity: 1
        }]
      })
      render json: { id: session.id }
    end
  
    # Invoice Webhook
    def webhook
      payload = request.body.read
      sig_header = request.env['HTTP_STRIPE_SIGNATURE']
      secret = ENV["STRIPE_WEBHOOK_SECRET"]
  
      event = Stripe::Webhook.construct_event(payload, sig_header, secret)
  
      case event.type
      when 'checkout.session.completed'
        session = event.data.object
        handle_checkout_completed(session)
      when 'invoice.payment_succeeded'
        invoice = event.data.object
        handle_successful_payment(invoice)
      else
        Rails.logger.info "Unhandled event type: #{event.type}"
      end
  
      render json: { message: 'success' }, status: :ok
    rescue JSON::ParserError => e
      render json: { error: 'Invalid payload' }, status: :bad_request
    rescue Stripe::SignatureVerificationError => e
      render json: { error: 'Invalid signature' }, status: :bad_request
    end
  
    # Subscription Cancel
    def cancel
      return head :bad_request unless Current.user&.subscription_id
      begin
        Stripe::Subscription.update(Current.user.subscription_id, { cancel_at_period_end: true })
        Current.user.update(subscription_status: "canceled")
        head :ok
      rescue => e
        Rails.logger.error("Stripe cancel error: #{e.message}")
        head :internal_server_error
      end
    end
  
    private
  
    # Create or fetch Stripe customer for the user
    def find_or_create_stripe_customer(user)
      if user.stripe_customer_id.present?
        Stripe::Customer.retrieve(user.stripe_customer_id)
      else
        customer = Stripe::Customer.create(
          email: user.email_address,
          name: "#{user.name} #{user.surname}",
          phone: user.mobile_number,
          address: {
            line1: user.address,
            city: "Mumbai",
            state: "MH",
            postal_code: "400001",
            country: "IN"
          }
        )
        user.update(stripe_customer_id: customer.id)
        customer
      end
    end
  
    # Save subscription ID after checkout completes
    def handle_checkout_completed(session)
      user = User.find_by(stripe_customer_id: session.customer)
      return unless user
  
      user.update!(
        subscription_id: session.subscription,
        subscription_status: "active"
      )
    end
  
    # Mark subscription as paid when invoice is paid
    def handle_successful_payment(invoice)
      stripe_subscription_id = invoice.subscription
      customer_id = invoice.customer
  
      user = User.find_by(stripe_customer_id: customer_id)
      return unless user
  
      # Update custom Subscription model if used
      subscription = Subscription.find_or_initialize_by(stripe_subscription_id: stripe_subscription_id, user: user)
      subscription.status = "paid"
      subscription.current_period_end = Time.at(invoice.lines.data[0].period.end) if invoice.lines.data.any?
      subscription.save!
  
      # Update user status
      user.update!(subscription_status: "paid") unless user.subscription_status == "paid"
    end
  end
  