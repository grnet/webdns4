Rails.application.routes.draw do
  # Override devise user removal
  devise_scope :users do
    delete :users, to: redirect('/')
  end
  devise_for :users

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
    resources :records, except: [:index, :show] do
      # Reuse records#update instead of introducing new controller actions
      #
      # rubocop:disable Style/AlignHash
      put :disable, to: 'records#update', on: :member,
          defaults: { record: { disabled: true } }
      put :enable,  to: 'records#update', on: :member,
          defaults: { record: { disabled: false } }
      # rubocop:enable Style/AlignHash
    end
  end

  # Admin
  namespace :admin do
    root to: redirect('/admin/groups')

    resources :groups, except: [:show]
  end

  # Private
  put 'private/replace_ds', to: 'private#replace_ds'
end

