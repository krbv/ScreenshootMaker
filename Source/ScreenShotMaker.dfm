object Form1: TForm1
  Left = 192
  Top = 124
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Screen Recorder'
  ClientHeight = 127
  ClientWidth = 118
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnPaint = FormPaint
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object btnstart: TButton
    Left = 24
    Top = 48
    Width = 75
    Height = 25
    Caption = 'Run'
    TabOrder = 0
    OnClick = btnstartClick
  end
  object tmr1: TTimer
    Enabled = False
    OnTimer = tmr1Timer
    Top = 96
  end
  object cleaner: TTimer
    Interval = 300000
    OnTimer = cleanerTimer
    Left = 88
    Top = 96
  end
end
