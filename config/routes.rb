Rails.application.routes.draw do
  # Override devise user removal
  devise_scope :users do
    delete :users, to: redirect('/')
  end
  devise_for :users
  get '/auth/saml', to: 'auth#saml'

  root to: redirect('/domains')

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

    resources :groups, except: [:show]
    resources :jobs, only: [:index, :destroy]
    resources :users, only: [] do
      get :orphans, to: 'users#orphans', on: :collection
      put :update_groups, to: 'users#update_groups', on: :collection
    end
  end

  # Private
  put 'private/replace_ds', to: 'private#replace_ds'
  put 'private/trigger_event', to: 'private#trigger_event'
end

