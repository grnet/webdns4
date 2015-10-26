Rails.application.routes.draw do
  get '/', to: redirect('/domains')

  resources :domains do
    resources :records, except: [:index, :show]
  end
end
