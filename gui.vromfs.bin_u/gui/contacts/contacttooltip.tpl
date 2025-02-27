tdiv {
  id:t='contact_tooltip'
  min-width:t='2@profileIconFullSize'
  flow:t='vertical'

  tdiv {
    img {
      size:t='1@profileIconFullSize, 1@profileIconFullSize'
      background-svg-size:t='1@profileIconFullSize, 1@profileIconFullSize'
      background-image:t='<<icon>>'
      <<#hasAvatarFrame>>
      margin:t='0.1@profileIconFullSize'
      avatarFrame {
        size:t='1.2 * pw, 1.2 * ph'
        pos:t='(pw-w)/2, (ph-h)/2'
        position:t='absolute'
        background-color:t='@white'
        background-scale:t='aspect-ratio'
        background-image:t='!ui/images/avatar_frames/<<frame>>.avif'
        background-svg-size:t='1.2 * pw, 1.2 * ph'
      }
      <</hasAvatarFrame>>
    }
    tdiv {
      min-width:t='pw'
      height:t='1@profileIconFullSize'
      flow:t='vertical'
      margin-left:t='1@blockInterval'
      tdiv {
        min-width:t='1@profileIconFullSize'
        pos:t='pw - w, 0'
        position:t='relative'
        textareaNoTab {
          id:t='contact-presenceText'
          pos:t='pw - w, 0'
          position:t='relative'
          text:t='<<presenceText>>'
          tinyFont:t='yes'
        }
      }
      tdiv{
        pos:t='pw/2 - w/2, ph/2 - h'
        position:t='relative'
        flow:t='vertical'
        textAreaCentered {
          position:t='relative'
          halign:t='center'
          text:t='<<name>>'
          smallFont:t='yes'
        }
        textAreaCentered {
          position:t='relative'
          halign:t='center'
          text:t='<<wtName>>'
          tinyFont:t='yes'
        }
        textAreaCentered {
          position:t='relative'
          halign:t='center'
          text:t='<<title>>'
          tinyFont:t='yes'
        }
      }
    }
  }
  <<#hasUnitList>>
  tdiv {
    id:t='contact-aircrafts'
    flow:t='vertical'
    min-width:t='pw'

    <<#unitList>>
    tdiv {
      width:t='pw'
      <<#header>>
      text {
        text:t='<<header>>'
        smallFont:t='yes'
        overlayTextColor:t='userlog'
      }

      text {
        text:t='#ui/colon'
        smallFont:t='yes'
        overlayTextColor:t='userlog'
      }
      <</header>>

      unitContactRow{
        width:t='pw'
        <<#even>>
          even:t='yes'
        <</even>>
        <<#unit>>
        tdiv{
          width:t='pw/4'
          img {
            halign:t='center'
            valign:t='center'
            size:t='<<#isWideIco>>2<</isWideIco>>@sIco, @sIco'
            background-svg-size:t='<<#isWideIco>>2<</isWideIco>>@sIco, @sIco'
            background-image:t='<<icon>>'
            background-repeat:t='aspect-ratio'
          }
        }
          activeText {
            width:t='fw'
            valign:t='center'
            text:t='#<<unit>>_shop'
            smallFont:t='yes'
          }
          text {
            width:t='pw/4'
            valign:t='center'
            text:t='<<rank>>'
            smallFont:t='yes'
          }
        <</unit>>
      }
    }
    <</unitList>>

    text {
      text:t='<<hint>>'
      halign:t='center'
      smallFont:t='yes'
    }
  }
  <</hasUnitList>>
}
