Rails.application.routes.draw do
  get '/', to: redirect('/domains')

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
