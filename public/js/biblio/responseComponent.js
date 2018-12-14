Vue.component('response-component', {
  template: "#response-modal",
  created() {
    this.fetchResponse();
  },
  data: function() {
    return {
      errors: [],
      identifier_name: this.identifier_name,
      type: this.type,
      id: this.id,
      success: false,
    }
  },
  methods: {
    fetchResponse() {
      axios.get(baseendpoint+'config', {
        headers: { Authorization: apitoken },
        params: {
          service: 'biblio',
          table: 'Response',
          interface_id: this.config.id,
        }
      }).then(response => {
          var data = response.data.pop();
          this.identifier_name = data.identifier_name;
          this.type = data.type;
          this.id = data.id;
      }).catch(error => {
          console.log(error.response.data);
      });
    },
    addResponse() {
      axios.post(baseendpoint+'config', 
        {
          service: 'biblio',
          table: 'Response',
          params: {interface_id: this.config.id, identifier_name: this.identifier_name, type: this.type}
        },
        {headers: { Authorization: apitoken }}
      ).then(response => {
        this.fetchResponse();
        this.success = true;
      }).catch(error => {
        console.log(error.response.data);
      });
    },
    deleteResponse(e) {
      this.success = false;
      e.preventDefault();
      axios.delete(baseendpoint+'config',
      {
        headers: { Authorization: apitoken },
        params: {
          service: 'biblio',
          table: 'Response',
          id: this.id
        }
      }
    ).then(response => {
      this.fetchResponse();
      this.identifier_name = "";
      this.type = "";
      this.id = "";
    }).catch(error => {
      console.log(error.response.data);
    });
    },
    updateResponse(e) {
      e.preventDefault();
      axios.put(baseendpoint+'config',
      {
        service: 'biblio',
        table: 'Response',
        id: this.id,
        params: {identifier_name: this.identifier_name, type: this.type}
      },
      {headers: { Authorization: apitoken }}
    ).then(response => {
        this.fetchResponse();
        this.success = true;
    }).catch(error => {
      console.log(error.response.data);
    });
    },
    checkForm(e) {
      e.preventDefault();
      this.success = false;
      if (this.id && this.identifier_name && this.type) {
        this.updateResponse(e);
      }
      if (!this.id &&this.identifier_name && this.type) {
        this.addResponse();
      } 
      this.errors = [];
      
      if (!this.identifier_name) {
        this.errors.push('Identifier field name is required.');
      }
      if (!this.type) {
        this.errors.push('Type is required.');
      }
    }
  },
  props: ['config']
});