class CardsController < ApplicationController
  require "payjp"
  before_action :set_card
  before_action :set_parents, only: [:show, :new]

  def show
    if @card.present?
      Payjp.api_key = Rails.application.credentials[:payjp][:PAYJP_PRIVATE_KEY]
      customer = Payjp::Customer.retrieve(@card.customer_id)
      @card_information = customer.cards.retrieve(@card.card_id)

      # 《＋α》 登録しているカード会社のブランドアイコンを表示するためのコードです。---------
      @card_brand = @card_information.brand      
      case @card_brand
      when "Visa"
        @card_src = "if-visa-2593666_86609.svg"
      when "JCB"
        @card_src = "jcbcard.png"
      when "MasterCard"
        @card_src = "mastercard.png"
      when "American Express"
        @card_src = "americancard.png"
      when "Diners Club"
        @card_src = "diners_club.png"
      when "Discover"
        @card_src = "discover.png"
      end
      # ---------------------------------------------------------------
    end
  end

  def new # カードの登録画面。送信ボタンを押すとcreateアクションへ。
    card = Card.where(user_id: current_user.id).first
    redirect_to card_path(card.id) if card.present?
  end


  def create #PayjpとCardのデータベースを作成
    Payjp.api_key = Rails.application.credentials[:payjp][:PAYJP_PRIVATE_KEY]
    if params['payjp-token'].blank?
      redirect_to action: "new", alert: 'クレジットカード情報を入力してください。'
    else
      # トークンが正常に発行されていたら、顧客情報をPAY.JPに登録します。
      customer = Payjp::Customer.create(
        description: 'test', # 無くてもOK。PAY.JPの顧客情報に表示する概要です。
        email: current_user.email,
        card: params['payjp-token'], # 直前のnewアクションで発行され、送られてくるトークンをここで顧客に紐付けて永久保存します。
        metadata: {user_id: current_user.id} # 無くてもOK。
      )
      @card = Card.new(user_id: current_user.id, customer_id: customer.id, card_id: customer.default_card)
      if @card.save
        redirect_to card_path(@card.id), notice: 'クレジットカード情報を登録しました。'
      else
        redirect_to action: "new", alert: 'クレジットカード情報が正しくありません。'
      end
    end
  end


  def destroy #PayjpとCardのデータベースを削除
    Payjp.api_key = Rails.application.credentials[:payjp][:PAYJP_PRIVATE_KEY]
    customer = Payjp::Customer.retrieve(@card.customer_id)
    customer.delete
    if @card.destroy #削除に成功した時にポップアップを表示します。
      redirect_to action: "show", notice: '削除しました'
    else #削除に失敗した時にアラートを表示します。
      redirect_to action: "show", alert:  '削除できませんでした'
    end
  end

  private

  def set_card
    @card = Card.where(user_id: current_user.id).first if Card.where(user_id: current_user.id).present?
  end

  def set_parents
    @parents = Category.where(ancestry: nil)
  end


end