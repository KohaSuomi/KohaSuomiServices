// Ready translated locale messages
const configurations = {
    en: {
      configurations: "Configuration"
    },
    fi: {
      configurations: "Asetukset"
    }
}

// Create VueI18n instance with options
const i18n = new VueI18n({
    locale: 'fi', // set locale
    configurations, // set locale messages
})

new Vue({ i18n }).$mount('#app')