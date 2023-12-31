<h1 align="center">
  <br>
     <img width="184" alt="kairos-white-column 5bc2fe34" src="https://user-images.githubusercontent.com/2420543/193010398-72d4ba6e-7efe-4c2e-b7ba-d3a826a55b7d.png">
    <br>
<br>
</h1>

<h3 align="center">Kairos Framework Images</h3>
<p align="center">
  <a href="https://github.com/kairos-io/kairos/issues"><img src="https://img.shields.io/github/issues/kairos-io/kairos"></a>
  <a href="https://github.com/kairos-io/kairos-framework/actions/workflows/release.yaml"> <img src="https://github.com/kairos-io/kairos/actions/workflows/release.yaml/badge.svg"></a>
</p>

<p align="center">
     <br>
    The immutable Linux meta-distribution for edge Kubernetes.
</p>

<hr>

Kairos Framework Images, include all the packages that will be used commonly across distributions in order to convert a Linux Distribution into a Kairos Linux.

## Security Profile

The major distinction between the two types of images is the security profile:

- generic: includes the traditional packages, this is what all released Kairos artifacts use
- fips: includes FIPS packages which you can use to build a Kairos image that follows the FIPS requirements if you also pair it with a FIPS complient Linux Distribution