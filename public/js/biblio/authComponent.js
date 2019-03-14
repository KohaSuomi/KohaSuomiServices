Vue.component('auth-component', {
  template: "#auth-modal",
  created() {
    this.fetchAuthUsers();
  },
  data: function() {
    return {
      showUserLinks: false,
      showAuthUrl: false,
      showEdit: true,
      links: [],
      auth: {},
      errors: [],
      auths: [],
      username: "",
      password: "",
      apikey: "",
      userid: "",
      auth_url: this.config.auth_url
    }
  },
  methods: {
    linksToggle(auth){
      this.auth = auth;
      this.fetchUserLinks();
      this.showUserLinks = !this.showUserLinks;
    },
    fetchAuthUsers() {
      axios.get(baseendpoint+'config', {
        headers: { Authorization: apitoken },
        params: {
          service: 'biblio',
          table: 'AuthUsers',
          interface_id: this.config.id,
        }
      }).then(response => {
          this.auths = response.data;
          if(this.config.auth_url == "" || this.config.auth_url == null) {
            this.showAuthUrl = true;
            this.showEdit = false;
          }
          this.showUserLinks = false;
      }).catch(error => {
          console.log(error.response.data);
      });
    },
    addAuth() {
      axios.post(baseendpoint+'config', 
        {
          service: 'biblio',
          table: 'AuthUsers',
          params: {interface_id: this.config.id, apikey: this.apikey, username: this.username, password: this.password}
        },
        {headers: { Authorization: apitoken }}
      ).then(response => {
        this.fetchAuthUsers();
      }).catch(error => {
        console.log(error.response.data);
      });
    },
    addAuthUrl() {
      axios.put(baseendpoint+'config',
        {
          service: 'biblio',
          table: 'interface',
          id: this.config.id,
          params: {auth_url: this.auth_url}
        },
        {headers: { Authorization: apitoken }}
      ).then(response => {
          this.toggleAuthUrl();
          this.showEdit = true;
      });
    },
    removeAuthUrl() {
      axios.put(baseendpoint+'config',
        {
          service: 'biblio',
          table: 'interface',
          id: this.config.id,
          params: {auth_url: ""}
        },
        {headers: { Authorization: apitoken }}
      ).then(response => {
          this.auth_url = "";
          this.showAuthUrl = true;
          this.showEdit = false;
      });
    },
    toggleAuthUrl() {
      this.showAuthUrl = !this.showAuthUrl;
    },
    addUserLinks() {
      axios.post(baseendpoint+'config', 
        {
          service: 'biblio',
          table: 'UserLinks',
          params: {interface_id: this.config.id, authuser_id: this.auth.id, username: this.userid}
        },
        {headers: { Authorization: apitoken }}
      ).then(response => {
            this.fetchUserLinks();
      }).catch(error => {
        console.log(error.response.data);
      });
    },
    fetchUserLinks() {
      axios.get(baseendpoint+'config', {
        headers: { Authorization: apitoken },
        params: {
          service: 'biblio',
          table: 'UserLinks',
          authuser_id: this.auth.id,
        }
      }).then(response => {
          this.links = response.data;
      }).catch(error => {
          console.log(error.response.data);
      });
    },
    removeUserLinks(id) {
      axios.delete(baseendpoint+'config', 
      {
        headers: { Authorization: apitoken },
        params: {
          service: 'biblio',
          table: 'UserLinks',
          id: id
        }
      }
      ).then(response => {
          this.fetchUserLinks();
      }).catch(error => {
        console.log(error.response.data);
      });
    },
    checkForm(e) {
      e.preventDefault();
      if (this.username && (this.password || this.apikey)) {
        this.addAuth();
      } 
      this.errors = [];

      if (!this.username) {
        this.errors.push('Userame required.');
      }
      if (!this.password && !this.apikey) {
        this.errors.push('Password or api key required.');
      }
    },
    checkAuthUrl(e) {
      e.preventDefault();
      var url_validate = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/;
      if (!this.auth_url) {
        this.addAuthUrl();
      }
      if (url_validate.test(this.auth_url)) {
        this.addAuthUrl();
      } 
      this.errors = [];

      if (this.auth_url && !url_validate.test(this.auth_url)) {
        this.errors.push('Incorrect url.');
      }
    }
  },
  props: ['config']
});
Vue.component('auth-list', {
    template: "#list-auths",
    data: function() {
      return {
        showUpdate: false
      }
    },
    methods: {
      updateAuth(e) {
        e.preventDefault();
        axios.put(baseendpoint+'config',
        {
          service: 'biblio',
          table: 'AuthUsers',
          id: this.auth.id,
          params: {apikey: this.auth.apikey, username: this.auth.username, password: this.auth.password}
        },
        {headers: { Authorization: apitoken }}
      ).then(response => {
          this.updateToggle();
        }).catch(error => {
          console.log(error.response.data);
        });
      },
      deleteAuth(e) {
        e.preventDefault();
        axios.delete(baseendpoint+'config',
        {
          headers: { Authorization: apitoken },
          params: {
            service: 'biblio',
            table: 'AuthUsers',
            id: this.auth.id
          }
        }
      ).then(response => {
          this.$parent.fetchAuthUsers();
        }).catch(error => {
          console.log(error.response.data);
        });
      },
      updateToggle(){
          this.showUpdate = !this.showUpdate;
      },
      linksToggle() {
        this.$parent.linksToggle(this.auth);
      }
    },
    props: ['auth']
  });