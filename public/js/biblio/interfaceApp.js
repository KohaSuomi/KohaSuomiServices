new Vue({
    el: '#interfaceApp',
    created() {
        this.fetchData();	
    },
    data: {
        errors: [],
        configs: [],
        parameters: [],
        interface: "",
        name: "",
        type: "",
        method: "",
        format: "",
        endpoint_url: "",
        auth_url: "",
        parametername: "",
        parametertype: "",
        parametervalue: "",
        parameterforce: "",
    },
    methods: {
        fetchData() {
        axios.get(baseendpoint+'config', {
          headers: { Authorization: apitoken },
          params: {
            service: 'biblio',
            table: 'interface'
          }
        }).then(response => {
            this.configs = response.data;
            });
        },
        fetchParameters(id) {
        axios.get(baseendpoint+'config', {
          headers: { Authorization: apitoken },
          params: {
            service: 'biblio',
            table: 'parameter',
            interface_id: id,
          }
        }).then(response => {
            this.parameters = response.data;
        }).catch(error => {
            console.log(error.response.data);
        });
        },
        addParameter(params) {
        axios.post(baseendpoint+'config', 
          {
            service: 'biblio',
            table: 'parameter',
            params: params
          },
          {headers: { Authorization: apitoken }}
        ).then(response => {
              
        }).catch(error => {
          console.log(error.response.data);
        });
        },
        addConfig() {
        axios.post(baseendpoint+'config',
          {
            service: 'biblio',
            table: 'interface',
            params: {interface: this.interface, name: this.name, type: this.type, method: this.method, format: this.format, endpoint_url: this.endpoint_url}
          },
          {headers: { Authorization: apitoken }}
        ).then(response => {
            this.fetchData();
        }).catch(error => {
              console.log(error.response.data);
        });
        },
        updateConfig(config) {
          axios.put(baseendpoint+'config',
          {
            service: 'biblio',
            table: 'interface',
            id: config.id,
            params: {interface: config.interface, name: config.name, type: config.type, method: config.method, format: config.format, endpoint_url: config.endpoint_url}
          },
          {headers: { Authorization: apitoken }}
        ).then(response => {
            
            });
        },
        deleteConfig(config) {
          axios.delete(baseendpoint+'config',
          {
            headers: { Authorization: apitoken },
            params: {
              service: 'biblio',
              table: 'interface',
              id: config.id
            }
          }
        ).then(response => {
            this.fetchData();
            });
        },
        deleteParameter(id) {
          axios.delete(baseendpoint+'config',
          {
            headers: { Authorization: apitoken },
            params: {
              service: 'biblio',
              table: 'parameter',
              id: id
            }
          }
        ).then(response => {
            });
        },
        checkForm(e) {
            var url_validate = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/;
          if (this.name && this.interface && this.type && this.endpoint_url && url_validate.test(this.endpoint_url)) {
            this.addConfig();
          } 
          this.errors = [];

          if (!this.name) {
            this.errors.push('Name required.');
          }
          if (!this.interface) {
            this.errors.push('Interface required.');
          }
          if (!this.type) {
            this.errors.push('Type required.');
          }
          if (!this.endpoint_url) {
            this.errors.push('Url required.');
          }
          if (!url_validate.test(this.endpoint_url)) {
            this.errors.push('Incorrect url.');
          }
          e.preventDefault();
        }
    }
});
Vue.component('config-list', {
  template: "#list-items",
  data: function() {
    return {
      showUpdate: false,
      host: this.config.host
    }
  },
  methods: {
    updateConfig(config){
        this.showUpdate = false;
        this.$parent.updateConfig(config);
    },
    deleteConfig(config){
        this.showUpdate = false;
        this.$parent.deleteConfig(config);
    },
    fetchParameters(config){
        this.$parent.fetchParameters(config.id);
    },
    updateToggle(){
        this.showUpdate = !this.showUpdate;
    },
    updateHost() {
      this.host = !this.host;
      axios.put(baseendpoint+'config',
        {
          service: 'biblio',
          table: 'interface',
          id: this.config.id,
          params: {host: this.host}
        },
        {headers: { Authorization: apitoken }}
        ).then(response => {
          this.$parent.fetchData();
        }).catch(error => {
          console.log(error.response.data);
        });
    }
  },
  props: ['config', 'parameters']
});
Vue.component('modal-component', {
  template: "#parameter-modal",
  data: function() {
    return {
      parametername: "",
      parametertype: "",
      parametervalue: "",
      parameterforce: ""
    }
  },
  methods: {
    addParameter(interface_id, e) {
      e.preventDefault();
      var params = {interface_id: interface_id, name: this.parametername, type: this.parametertype, value: this.parametervalue, force_tag: this.parameterforce};
      this.$parent.$parent.addParameter(params);
      this.$parent.$parent.fetchParameters(interface_id);
    },
    deleteParameter(parameter, e) {
      e.preventDefault();
      this.$parent.$parent.deleteParameter(parameter.id);
      this.$parent.$parent.fetchParameters(parameter.interface_id);
    }
  },
  props: ['config','parameters']
});
Vue.component('auth-component', {
  template: "#auth-modal",
  created() {
    this.fetchAuthUsers();
  },
  data: function() {
    return {
      showUserLinks: false,
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
      this.showUserLinks = true;
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
    deleteAuth(id, e) {
      e.preventDefault();
      axios.delete(baseendpoint+'config',
      {
        headers: { Authorization: apitoken },
        params: {
          service: 'biblio',
          table: 'AuthUsers',
          id: id
        }
      }
    ).then(response => {
        this.fetchAuthUsers();
      }).catch(error => {
        console.log(error.response.data);
      });
    },
    updateAuth(auth, e) {
      e.preventDefault();
      axios.put(baseendpoint+'config',
      {
        service: 'biblio',
        table: 'AuthUsers',
        id: auth.id,
        params: {apikey: auth.apikey, username: auth.username, password: auth.password}
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
          
      });
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