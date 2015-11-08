Rails.application.routes.draw do
  # Override devise user removal
  devise_scope :users do
    delete :users, to: redirect('/')
  end
  devise_for :users

  root to: redirect('/domains')

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
end
