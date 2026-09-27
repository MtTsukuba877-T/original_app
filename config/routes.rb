Rails.application.routes.draw do
  devise_for :users
  resources :companies, only: [ :index, :new, :create, :show ]

  namespace :company_users do
    get "dashboard", to: "dashboards#show", as: :dashboard

    # 名簿管理関連（Issue #23: CSV 名簿アップロード機能）
    # MVP では CSV アップロードとテンプレートダウンロードのみ実装。
    # Issue #25 で index（名簿一覧）、本リリース版で個別追加・編集（Issue #26, #27）を追加予定。
    resources :employees, only: [] do
      collection do
        get :csv_upload           # CSV アップロード画面表示
        post :csv_import          # CSV アップロード実行
        get :csv_template         # テンプレート CSV ダウンロード
      end
    end
  end

  # 受検者機能（Phase 5）
  # 受検者は Devise ではなく独自の SessionsController で認証する（Issue #39）。
  # ログアウトは Issue #47 で追加。
  namespace :examinees do
    get "sign_in", to: "sessions#new", as: :sign_in
    post "sign_in", to: "sessions#create"
    delete "sign_out", to: "sessions#destroy", as: :sign_out
    get "home", to: "homes#show", as: :home
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # 開発環境: letter_opener_web のメール確認画面
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # Defines the root path route ("/")
  root "home#index"
end
