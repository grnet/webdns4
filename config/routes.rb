Rails.application.routes.draw do
  # Override devise user removal
  devise_scope :users do
    delete :users, to: redirect('/')
  end
  devise_for :users
  get '/auth/saml', to: 'auth#saml'

  root to: redirect('/domains')

  resources :users, only: [] do
    get :token, to: 'users#token', on: :member
    post :generate_token, to: 'users#generate_token', on: :member
    resources :domains, only: [] do
      put :mute, to: 'users#mute'
      put :unmute, to: 'users#unmute'
      put :mute, to: 'users#mute_all', on: :collection
      put :unmute, to: 'users#unmute_all', on: :collection
    end
  end

  resources :groups, only: [:show] do
    get :search_member,
        to: 'groups#search_member', on: :member
    post :members,
         to: 'groups#create_member', as: :create_member, on: :member
    delete 'member/:user_id',
           to: 'groups#destroy_member', as: :destroy_member, on: :member
  end

  resources :domains do
    get :edit_dnssec, to: 'domains#edit_dnssec', on: :member
    delete :full_destroy, to: 'domains#full_destroy', on: :member

    resources :records, except: [:index, :show] do
      # Reuse records#update instead of introducing new controller actions
      #
      # rubocop:disable Style/AlignHash
      put :disable, to: 'records#update', on: :member,
          defaults: { record: { disabled: true } }
      put :enable,  to: 'records#update', on: :member,
          defaults: { record: { disabled: false } }

      put :editable, to: 'records#editable', on: :collection
      post :valid, to: 'records#valid', on: :collection
      post :bulk, to: 'records#bulk', on: :collection
      # rubocop:enable Style/AlignHash
    end
  end

  get '/records/search', to: 'records#search'

  # Admin
  namespace :admin do
    root to: redirect('/admin/groups')

    resources :users, except: [:show]
    resources :groups, except: [:show]
    resources :jobs, only: [:index, :destroy] do
      put :done, to: 'jobs#update', on: :member,
          defaults: { job: { status: 1 } }
      put :pending,  to: 'jobs#update', on: :member,
          defaults: { job: { status: 0 } }
      get '/type/:category', to: 'jobs#index', on: :collection,
          constraints: proc { |req| ['completed', 'pending'].include?(req.params[:category]) }
    end
    resources :users, only: [:destroy] do
      get :orphans, to: 'users#orphans', on: :collection
      put :update_groups, to: 'users#update', on: :collection
    end
  end

  # API
  scope '/api' do
    get :ping, to: 'api#ping'
    get :whoami, to: 'api#whoami'
    get '/domain/:domain/list', to: 'api#list', constraints: { domain: /[^\/]+/}
    post '/domain/:domain/bulk', to: 'api#bulk', constraints: { domain: /[^\/]+/}
    get :domains, to: 'api#domains'
  end if WebDNS.settings[:api]

  # Private
  put 'private/replace_ds', to: 'private#replace_ds'
  put 'private/trigger_event', to: 'private#trigger_event'
  get 'private/zones', to: 'private#zones'

  get 'help/api', to: 'help#api'
end

