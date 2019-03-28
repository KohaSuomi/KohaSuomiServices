new Vue({
    el: '#loginApp',
    data: {
        errors: [],
        username: "",
        password: "",
    },
    methods: {
        login() {
        axios.post(baseendpoint+'auth',
        {
          username: this.username,
          password: this.password
        }
        ).then(response => {
            window.location.href = servicepath;
          }).catch(error => {
            this.errors = [];
            this.errors.push(error.response.data.error);
          });
        }
    }
});